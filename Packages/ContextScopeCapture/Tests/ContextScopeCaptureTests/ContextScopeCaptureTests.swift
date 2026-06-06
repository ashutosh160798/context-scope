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
}
