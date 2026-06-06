import XCTest
import ContextScopeCore
@testable import ContextScopeVisualization

final class RiverLayoutTests: XCTestCase {
    private func snapshot(items: [ContextItem], limit: Int?) -> ContextSnapshot {
        ContextSnapshot(
            runID: UUID(),
            items: items,
            totalTokens: items.reduce(0) { $0 + $1.tokenCount },
            contextLimit: limit
        )
    }

    func testLanesAggregateByCategory() {
        let snap = snapshot(items: [
            ContextItem(category: .systemPrompt, tokenCount: 100, estimatedTokenCount: true, content: "a"),
            ContextItem(category: .conversationHistory, tokenCount: 200, estimatedTokenCount: true, content: "b"),
            ContextItem(category: .conversationHistory, tokenCount: 100, estimatedTokenCount: true, content: "c"),
        ], limit: 1000)
        let lanes = RiverLayout.lanes(from: snap)
        XCTAssertEqual(lanes.count, 2)
        XCTAssertEqual(lanes.first { $0.id == .conversationHistory }?.tokenCount, 300)
    }

    func testProportionUsesContextLimitAsDenominator() {
        let snap = snapshot(items: [
            ContextItem(category: .systemPrompt, tokenCount: 250, estimatedTokenCount: true, content: "a"),
        ], limit: 1000)
        let lanes = RiverLayout.lanes(from: snap)
        XCTAssertEqual(lanes.first?.proportion ?? 0, 0.25, accuracy: 0.0001)
    }

    func testProportionFallsBackToTotalTokensWhenNoLimit() {
        let snap = snapshot(items: [
            ContextItem(category: .systemPrompt, tokenCount: 50, estimatedTokenCount: true, content: "a"),
            ContextItem(category: .toolOutputs, tokenCount: 50, estimatedTokenCount: true, content: "b"),
        ], limit: nil)
        let lanes = RiverLayout.lanes(from: snap)
        XCTAssertEqual(lanes.first { $0.id == .systemPrompt }?.proportion ?? 0, 0.5, accuracy: 0.0001)
    }

    func testLanesPreserveDisplayOrder() {
        let snap = snapshot(items: [
            ContextItem(category: .toolOutputs, tokenCount: 10, estimatedTokenCount: true, content: "a"),
            ContextItem(category: .systemPrompt, tokenCount: 10, estimatedTokenCount: true, content: "b"),
            ContextItem(category: .toolDefinitions, tokenCount: 10, estimatedTokenCount: true, content: "c"),
        ], limit: 100)
        let lanes = RiverLayout.lanes(from: snap)
        XCTAssertEqual(lanes.map { $0.id }, [.systemPrompt, .toolDefinitions, .toolOutputs])
    }

    func testEmptyDenominatorReturnsNoLanes() {
        let snap = ContextSnapshot(runID: UUID(), items: [], totalTokens: 0, contextLimit: nil)
        XCTAssertTrue(RiverLayout.lanes(from: snap).isEmpty)
    }
}
