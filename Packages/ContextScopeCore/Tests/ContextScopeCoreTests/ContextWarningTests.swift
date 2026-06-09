import XCTest
@testable import ContextScopeCore

final class ContextWarningTests: XCTestCase {
    private func item(_ category: ContextCategory, _ tokens: Int, content: String = "x") -> ContextItem {
        ContextItem(category: category, tokenCount: tokens, estimatedTokenCount: true, content: content)
    }

    private func snapshot(_ items: [ContextItem], limit: Int?) -> ContextSnapshot {
        ContextSnapshot(
            runID: UUID(),
            items: items,
            totalTokens: items.reduce(0) { $0 + $1.tokenCount },
            contextLimit: limit
        )
    }

    func testHealthySnapshotHasNoWarnings() {
        // 100 tokens out of 1000 = 10% pressure; each item is 20% of input.
        let snap = snapshot([
            item(.systemPrompt, 20, content: "sys"),
            item(.conversationHistory, 20, content: "hi"),
            item(.conversationHistory, 20, content: "yo"),
            item(.conversationHistory, 20, content: "ok"),
            item(.toolOutputs, 20, content: "out"),
        ], limit: 1000)
        XCTAssertTrue(snap.warnings.isEmpty)
    }

    func testPressureThresholds() {
        XCTAssertEqual(
            snapshot([item(.systemPrompt, 720)], limit: 1000).warnings.first { $0.kind == .contextPressure }?.severity,
            .notice
        )
        XCTAssertEqual(
            snapshot([item(.systemPrompt, 880)], limit: 1000).warnings.first { $0.kind == .contextPressure }?.severity,
            .warning
        )
        XCTAssertEqual(
            snapshot([item(.systemPrompt, 970)], limit: 1000).warnings.first { $0.kind == .contextPressure }?.severity,
            .critical
        )
    }

    func testNoPressureWarningWithoutLimit() {
        let snap = snapshot([item(.systemPrompt, 1_000_000)], limit: nil)
        XCTAssertNil(snap.warnings.first { $0.kind == .contextPressure })
    }

    func testDominantItemWarning() {
        // The "huge" history item is 60% of a 100-token input; the other two
        // items sit at 20% each, so only one item dominates.
        let snap = snapshot([
            item(.systemPrompt, 20, content: "sys"),
            item(.conversationHistory, 60, content: "huge"),
            item(.conversationHistory, 20, content: "small"),
        ], limit: nil)
        let dominant = snap.warnings.filter { $0.kind == .dominantItem }
        XCTAssertEqual(dominant.count, 1)
        XCTAssertTrue(dominant.first?.message.contains("conversation history") ?? false)
    }

    func testBloatedToolDefinitionsAggregatesAcrossItems() {
        // Two small tool defs that individually stay under the 25% dominant
        // threshold but together exceed the 20% aggregate bloat threshold.
        let snap = snapshot([
            item(.systemPrompt, 20, content: "sys"),
            item(.conversationHistory, 20, content: "hi"),
            item(.conversationHistory, 20, content: "yo"),
            item(.conversationHistory, 18, content: "ok"),
            item(.toolDefinitions, 11, content: "tool_a"),
            item(.toolDefinitions, 11, content: "tool_b"),
        ], limit: nil)
        let bloat = snap.warnings.filter { $0.kind == .bloatedToolDefinitions }
        XCTAssertEqual(bloat.count, 1)
        XCTAssertNil(snap.warnings.first { $0.kind == .dominantItem }, "No single item should dominate here")
    }

    func testDuplicateContentReportedOncePerCategory() {
        let snap = snapshot([
            item(.conversationHistory, 10, content: "repeated message"),
            item(.conversationHistory, 10, content: "repeated message"),
            item(.conversationHistory, 10, content: "repeated message"),
        ], limit: nil)
        XCTAssertEqual(snap.warnings.filter { $0.kind == .duplicateContent }.count, 1)
    }

    func testDistinctContentIsNotFlaggedAsDuplicate() {
        let snap = snapshot([
            item(.conversationHistory, 10, content: "first"),
            item(.conversationHistory, 10, content: "second"),
        ], limit: nil)
        XCTAssertNil(snap.warnings.first { $0.kind == .duplicateContent })
    }

    func testWarningsSortedBySeverityDescending() {
        // Critical pressure + a dominant item + a duplicate notice.
        let snap = snapshot([
            item(.systemPrompt, 970, content: "dup"),
            item(.conversationHistory, 30, content: "dup"),
        ], limit: 1000)
        let severities = snap.warnings.map { $0.severity }
        XCTAssertEqual(severities, severities.sorted(by: >))
        XCTAssertEqual(severities.first, .critical)
    }
}
