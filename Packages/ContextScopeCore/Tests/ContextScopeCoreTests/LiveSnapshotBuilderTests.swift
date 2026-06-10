import XCTest
@testable import ContextScopeCore

final class LiveSnapshotBuilderTests: XCTestCase {
    private let runID = UUID()

    func testSeedingProducesSnapshotFromRequestItems() {
        var builder = LiveSnapshotBuilder(runID: runID, contextLimit: 128_000)
        builder.seed(items: [
            ContextItem(category: .systemPrompt, tokenCount: 100, estimatedTokenCount: true, content: "sys"),
            ContextItem(category: .conversationHistory, tokenCount: 50, estimatedTokenCount: true, content: "hi"),
        ])
        let snapshot = builder.snapshot()
        XCTAssertEqual(snapshot.runID, runID)
        XCTAssertEqual(snapshot.totalTokens, 150)
        XCTAssertEqual(snapshot.contextLimit, 128_000)
        XCTAssertEqual(snapshot.items.count, 2)
    }

    func testStreamChunkAccumulatesIntoToolOutputsLane() {
        var builder = LiveSnapshotBuilder(runID: runID, contextLimit: nil)
        builder.seed(items: [
            ContextItem(category: .systemPrompt, tokenCount: 40, estimatedTokenCount: true, content: "sys"),
        ])
        // 8 characters -> 2 tokens at ~4 chars/token
        builder.apply(event: TraceEvent(runID: runID, kind: .streamChunk, payload: Data("abcdefgh".utf8)))
        let snapshot = builder.snapshot()
        XCTAssertEqual(snapshot.totalTokens, 42)
        XCTAssertEqual(snapshot.items.last?.category, .toolOutputs)
        XCTAssertEqual(snapshot.items.last?.tokenCount, 2)
    }

    func testEventsForOtherRunsAreIgnored() {
        var builder = LiveSnapshotBuilder(runID: runID, contextLimit: nil)
        builder.seed(items: [ContextItem(category: .systemPrompt, tokenCount: 10, estimatedTokenCount: true, content: "x")])
        builder.apply(event: TraceEvent(runID: UUID(), kind: .streamChunk, payload: Data("abcdefgh".utf8)))
        XCTAssertEqual(builder.snapshot().totalTokens, 10)
    }

    func testExactTokensFromResponseUsageOverrideHeuristic() throws {
        var builder = LiveSnapshotBuilder(runID: runID, contextLimit: 128_000)
        builder.seed(items: [
            ContextItem(category: .systemPrompt, tokenCount: 90, estimatedTokenCount: true, content: "sys"),
            ContextItem(category: .conversationHistory, tokenCount: 10, estimatedTokenCount: true, content: "hi"),
        ])
        // Simulate a few streaming chunks so streamedTokens > 0
        builder.apply(event: TraceEvent(runID: runID, kind: .streamChunk, payload: Data("hello".utf8)))

        // requestComplete carries the provider's usage object with exact counts
        let usageJSON = #"{"id":"x","usage":{"prompt_tokens":200,"completion_tokens":75,"total_tokens":275}}"#
        builder.apply(event: TraceEvent(runID: runID, kind: .requestComplete, payload: Data(usageJSON.utf8)))

        let snap = builder.snapshot()
        // totalTokens must equal exact input + exact output (275), not the heuristic sum
        XCTAssertEqual(snap.totalTokens, 275)
        // Output item must carry exact output tokens and be marked non-estimated
        let output = try XCTUnwrap(snap.items.last { $0.category == .toolOutputs })
        XCTAssertEqual(output.tokenCount, 75)
        XCTAssertFalse(output.estimatedTokenCount)
    }

    func testStreamedOutputRemainsEstimatedWithoutUsage() {
        var builder = LiveSnapshotBuilder(runID: runID, contextLimit: nil)
        builder.seed(items: [
            ContextItem(category: .systemPrompt, tokenCount: 40, estimatedTokenCount: true, content: "sys"),
        ])
        // 8 chars = 2 estimated tokens
        builder.apply(event: TraceEvent(runID: runID, kind: .streamChunk, payload: Data("abcdefgh".utf8)))
        // requestComplete with no usage field
        builder.apply(event: TraceEvent(runID: runID, kind: .requestComplete, payload: Data("{}".utf8)))

        let snap = builder.snapshot()
        XCTAssertEqual(snap.totalTokens, 42)
        XCTAssertEqual(snap.items.last?.estimatedTokenCount, true)
    }

    func testRequestCompleteForOtherRunIgnored() {
        var builder = LiveSnapshotBuilder(runID: runID, contextLimit: nil)
        builder.seed(items: [ContextItem(category: .systemPrompt, tokenCount: 50, estimatedTokenCount: true, content: "s")])
        let usageJSON = #"{"usage":{"prompt_tokens":999,"completion_tokens":1}}"#
        builder.apply(event: TraceEvent(runID: UUID(), kind: .requestComplete, payload: Data(usageJSON.utf8)))
        XCTAssertEqual(builder.snapshot().totalTokens, 50)
    }
}
