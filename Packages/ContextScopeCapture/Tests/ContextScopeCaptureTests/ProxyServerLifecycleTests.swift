import XCTest
import ContextScopeCore
@testable import ContextScopeCapture

final class ProxyServerLifecycleTests: XCTestCase {
    func testStartThenStopDoesNotThrow() async throws {
        let server = ProxyServer(
            port: 4329,
            upstreamBaseURL: URL(string: "https://api.openai.com")!,
            apiKey: "test"
        )
        try await server.start()
        await server.stop()
    }

    func testHealthEndpointRespondsOK() async throws {
        let server = ProxyServer(
            port: 4330,
            upstreamBaseURL: URL(string: "https://api.openai.com")!,
            apiKey: "test"
        )
        try await server.start()
        defer { Task { await server.stop() } }

        var request = URLRequest(url: URL(string: "http://127.0.0.1:4330/health")!)
        request.timeoutInterval = 5
        let (data, response) = try await URLSession.shared.data(for: request)
        let http = try XCTUnwrap(response as? HTTPURLResponse)
        XCTAssertEqual(http.statusCode, 200)
        XCTAssertEqual(String(data: data, encoding: .utf8), #"{"status":"ok"}"#)
    }

    func testDoubleStopIsSafe() async throws {
        let server = ProxyServer(
            port: 4331,
            upstreamBaseURL: URL(string: "https://api.openai.com")!,
            apiKey: "test"
        )
        try await server.start()
        await server.stop()
        await server.stop()
    }

    func testEventsStreamIsAccessible() async throws {
        // Verify the events stream is available after start (non-nil, iterable)
        let server = ProxyServer(
            port: 4332,
            upstreamBaseURL: URL(string: "https://api.openai.com")!,
            apiKey: "test"
        )
        try await server.start()
        defer { Task { await server.stop() } }
        // events is a let property; simply accessing it should not crash
        let _ = server.events
    }
}
