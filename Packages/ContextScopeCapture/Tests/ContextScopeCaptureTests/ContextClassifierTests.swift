import XCTest
import ContextScopeCore
@testable import ContextScopeCapture

final class ContextClassifierTests: XCTestCase {
    private let classifier = ContextClassifier()

    func testRoleMapping() {
        XCTAssertEqual(classifier.classify(role: "system", index: 0), .systemPrompt)
        XCTAssertEqual(classifier.classify(role: "user", index: 1), .conversationHistory)
        XCTAssertEqual(classifier.classify(role: "assistant", index: 2), .conversationHistory)
        XCTAssertEqual(classifier.classify(role: "tool", index: 3), .toolOutputs)
        XCTAssertEqual(classifier.classify(role: "function", index: 4), .toolOutputs)
    }

    func testRoleMappingIsCaseInsensitive() {
        XCTAssertEqual(classifier.classify(role: "SYSTEM", index: 0), .systemPrompt)
        XCTAssertEqual(classifier.classify(role: "User", index: 1), .conversationHistory)
    }

    func testUnknownRoleFallsBackToOther() {
        XCTAssertEqual(classifier.classify(role: "developer", index: 0), .other)
    }

    func testContentTypeMapping() {
        XCTAssertEqual(classifier.classify(contentType: "tool_definition"), .toolDefinitions)
        XCTAssertEqual(classifier.classify(contentType: "retrieved"), .retrievedContext)
        XCTAssertEqual(classifier.classify(contentType: "document"), .retrievedContext)
        XCTAssertEqual(classifier.classify(contentType: "mystery"), .other)
    }
}
