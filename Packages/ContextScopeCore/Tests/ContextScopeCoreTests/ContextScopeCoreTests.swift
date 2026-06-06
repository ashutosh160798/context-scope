import XCTest
@testable import ContextScopeCore

final class ContextScopeCoreTests: XCTestCase {
    func testContextItemCreation() {
        let item = ContextItem(
            category: .systemPrompt,
            tokenCount: 100,
            estimatedTokenCount: false,
            content: "You are a helpful assistant."
        )
        XCTAssertEqual(item.category, .systemPrompt)
        XCTAssertEqual(item.tokenCount, 100)
        XCTAssertFalse(item.estimatedTokenCount)
    }

    func testContextSnapshotPressure() {
        let item = ContextItem(
            category: .conversationHistory,
            tokenCount: 1000,
            estimatedTokenCount: true,
            content: "history"
        )
        let snap = ContextSnapshot(runID: UUID(), items: [item], totalTokens: 1000, contextLimit: 4000)
        XCTAssertEqual(snap.pressurePercent!, 25.0, accuracy: 0.01)
    }

    func testContextSnapshotNoPressureWhenNoLimit() {
        let snap = ContextSnapshot(runID: UUID(), items: [], totalTokens: 0, contextLimit: nil)
        XCTAssertNil(snap.pressurePercent)
    }

    func testContextSnapshotNoPressureWhenZeroLimit() {
        let snap = ContextSnapshot(runID: UUID(), items: [], totalTokens: 100, contextLimit: 0)
        XCTAssertNil(snap.pressurePercent)
    }

    func testTokenEstimatorHeuristic() {
        let estimator = TokenEstimator()
        let count = estimator.countTokens(in: "Hello, world!", model: "gpt-4o")
        XCTAssertGreaterThan(count, 0)
        XCTAssertFalse(estimator.isExact(for: "gpt-4o"))
    }

    func testModelRegistryExactMatch() {
        let registry = ModelRegistry()
        XCTAssertNotNil(registry.entry(for: "gpt-4o"))
        XCTAssertEqual(registry.entry(for: "gpt-4o")?.contextLimit, 128_000)
    }

    func testModelRegistryPrefixMatch() {
        let registry = ModelRegistry()
        XCTAssertNotNil(registry.entry(for: "gpt-4o-2024-11-20"))
    }

    func testModelRegistryMissing() {
        let registry = ModelRegistry()
        XCTAssertNil(registry.entry(for: "unknown-model-xyz"))
    }
}
