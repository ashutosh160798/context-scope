import XCTest
@testable import ContextScopeCapture

final class ContextScopeCaptureTests: XCTestCase {
    func testSanitizerRedactsAuthorizationHeader() {
        let sanitizer = Sanitizer()
        let headers = ["Authorization": "Bearer sk-abc123", "Content-Type": "application/json"]
        let sanitized = sanitizer.sanitize(headers: headers)
        XCTAssertEqual(sanitized["Authorization"], "[REDACTED]")
        XCTAssertEqual(sanitized["Content-Type"], "application/json")
    }

    func testSanitizerRedactsApiKey() {
        let sanitizer = Sanitizer()
        let headers = ["x-api-key": "secret", "Accept": "application/json"]
        let sanitized = sanitizer.sanitize(headers: headers)
        XCTAssertEqual(sanitized["x-api-key"], "[REDACTED]")
        XCTAssertEqual(sanitized["Accept"], "application/json")
    }

    func testSanitizerPreservesNonSecretHeaders() {
        let sanitizer = Sanitizer()
        let headers = ["Content-Type": "application/json", "User-Agent": "test"]
        let sanitized = sanitizer.sanitize(headers: headers)
        XCTAssertEqual(sanitized["Content-Type"], "application/json")
        XCTAssertEqual(sanitized["User-Agent"], "test")
    }

    // MARK: - Content redaction

    func testContentRedactsBearerToken() {
        let sanitizer = Sanitizer()
        let input = #"{"auth":"Bearer sk-abcdefghijklmnopqrstuvwxyz1234"}"#
        let output = sanitizer.sanitize(content: input)
        XCTAssertFalse(output.contains("sk-abcdefghijklmnopqrstuvwxyz1234"))
        XCTAssertTrue(output.contains("[REDACTED]"))
    }

    func testContentRedactsOpenAIStyleKey() {
        let sanitizer = Sanitizer()
        let input = "using key sk-proj-ABCDEFGHIJKLMNOPQRSTUVWXYZ123456 to authenticate"
        let output = sanitizer.sanitize(content: input)
        XCTAssertFalse(output.contains("sk-proj-ABCDEFGHIJKLMNOPQRSTUVWXYZ123456"))
        XCTAssertTrue(output.contains("[REDACTED]"))
    }

    func testContentPreservesNormalText() {
        let sanitizer = Sanitizer()
        let input = "The weather today is sunny and the temperature is 72 degrees."
        XCTAssertEqual(sanitizer.sanitize(content: input), input)
    }

    func testContentRedactsApiKeyPattern() {
        let sanitizer = Sanitizer()
        let input = #"{"api_key":"supersecretkey1234567890abcdef"}"#
        let output = sanitizer.sanitize(content: input)
        XCTAssertFalse(output.contains("supersecretkey1234567890abcdef"))
        XCTAssertTrue(output.contains("[REDACTED]"))
    }
}
