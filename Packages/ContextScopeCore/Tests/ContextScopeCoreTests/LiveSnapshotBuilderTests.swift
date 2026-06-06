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
}
