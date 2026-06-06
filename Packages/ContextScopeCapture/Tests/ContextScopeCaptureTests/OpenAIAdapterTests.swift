import XCTest
import ContextScopeCore
@testable import ContextScopeCapture

final class OpenAIAdapterTests: XCTestCase {
    private func request(body: String) -> HTTPRequest {
        HTTPRequest(
            method: "POST",
            path: "/v1/chat/completions",
            headers: ["Content-Type": "application/json"],
            body: Data(body.utf8)
        )
    }

    func testParseRequestClassifiesRolesIntoCategories() throws {
        let adapter = OpenAIAdapter()
        let json = """
        {"model":"gpt-4o","messages":[
          {"role":"system","content":"You are helpful"},
          {"role":"user","content":"Hello there"},
          {"role":"assistant","content":"Hi!"}
        ]}
        """
        let parsed = try adapter.parseRequest(request(body: json))
        XCTAssertEqual(parsed.model, "gpt-4o")
        XCTAssertEqual(parsed.contextItems.count, 3)
        XCTAssertEqual(parsed.contextItems[0].category, .systemPrompt)
        XCTAssertEqual(parsed.contextItems[1].category, .conversationHistory)
        XCTAssertEqual(parsed.contextItems[2].category, .conversationHistory)
    }

    func testParseRequestAddsToolDefinitionItems() throws {
        let adapter = OpenAIAdapter()
        let json = """
        {"model":"gpt-4o","messages":[{"role":"user","content":"hi"}],
         "tools":[{"type":"function","function":{"name":"get_weather"}}]}
        """
        let parsed = try adapter.parseRequest(request(body: json))
        XCTAssertEqual(parsed.contextItems.filter { $0.category == .toolDefinitions }.count, 1)
    }

    func testParseRequestThrowsOnMissingBody() {
        let adapter = OpenAIAdapter()
        let req = HTTPRequest(method: "POST", path: "/v1/chat/completions", headers: [:], body: nil)
        XCTAssertThrowsError(try adapter.parseRequest(req)) { error in
            XCTAssertEqual(error as? AdapterError, .missingBody)
        }
    }

    func testParseRequestEstimatesTokensWithFourCharHeuristic() throws {
        let adapter = OpenAIAdapter()
        // content "12345678" = 8 scalars -> 2 tokens
        let json = #"{"model":"gpt-4o","messages":[{"role":"user","content":"12345678"}]}"#
        let parsed = try adapter.parseRequest(request(body: json))
        XCTAssertEqual(parsed.contextItems[0].tokenCount, 2)
        XCTAssertTrue(parsed.contextItems[0].estimatedTokenCount)
    }
}
