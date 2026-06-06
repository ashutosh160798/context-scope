import XCTest
@testable import ContextScopeDemoData

final class ContextScopeDemoDataTests: XCTestCase {
    func testRegistryHasThreeScenarios() {
        XCTAssertEqual(DemoScenarioRegistry.all.count, 3)
    }

    func testScenarioIDs() {
        let ids = DemoScenarioRegistry.all.map { $0.id }
        XCTAssertTrue(ids.contains("healthy_request"))
        XCTAssertTrue(ids.contains("bloated_context"))
        XCTAssertTrue(ids.contains("runaway_tool_loop"))
    }
}
