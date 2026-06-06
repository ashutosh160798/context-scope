import Foundation
import ContextScopeCore

public actor UpstreamForwarder {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func forward(request: HTTPRequest, to baseURL: URL) async throws -> HTTPResponse {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw ForwardError.invalidBaseURL
        }
        let pathComponents = URLComponents(string: request.path)
        components.path = (components.path.trimmingCharacters(in: .init(charactersIn: "/")) + "/" + (pathComponents?.path ?? request.path).trimmingCharacters(in: .init(charactersIn: "/"))).replacingOccurrences(of: "//", with: "/")
        if !components.path.hasPrefix("/") { components.path = "/" + components.path }
        components.query = pathComponents?.query

        guard let url = components.url else { throw ForwardError.invalidBaseURL }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method
        urlRequest.httpBody = request.body

        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else {
            throw ForwardError.invalidResponse
        }

        var responseHeaders: [String: String] = [:]
        for (key, value) in http.allHeaderFields {
            responseHeaders["\(key)"] = "\(value)"
        }

        return HTTPResponse(statusCode: http.statusCode, headers: responseHeaders, body: data)
    }

    // Streaming variant — yields raw SSE lines as they arrive
    public func forwardStreaming(
        request: HTTPRequest,
        to baseURL: URL,
        onChunk: @Sendable @escaping (Data) async -> Void
    ) async throws -> HTTPResponse {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw ForwardError.invalidBaseURL
        }
        let pathComponents = URLComponents(string: request.path)
        components.path = (components.path.trimmingCharacters(in: .init(charactersIn: "/")) + "/" + (pathComponents?.path ?? request.path).trimmingCharacters(in: .init(charactersIn: "/"))).replacingOccurrences(of: "//", with: "/")
        if !components.path.hasPrefix("/") { components.path = "/" + components.path }
        components.query = pathComponents?.query

        guard let url = components.url else { throw ForwardError.invalidBaseURL }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method
        urlRequest.httpBody = request.body
        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        let (byteStream, response) = try await session.bytes(for: urlRequest)
        guard let http = response as? HTTPURLResponse else { throw ForwardError.invalidResponse }

        var responseHeaders: [String: String] = [:]
        for (key, value) in http.allHeaderFields {
            responseHeaders["\(key)"] = "\(value)"
        }

        var accumulated = Data()
        for try await byte in byteStream {
            accumulated.append(byte)
            // Flush on newline to minimize latency
            if byte == UInt8(ascii: "\n") {
                await onChunk(accumulated)
                accumulated = Data()
            }
        }
        if !accumulated.isEmpty {
            await onChunk(accumulated)
        }

        return HTTPResponse(statusCode: http.statusCode, headers: responseHeaders, body: nil)
    }
}

public enum ForwardError: Error, LocalizedError {
    case invalidBaseURL
    case invalidResponse

    public var errorDescription: String? {
        switch self {
        case .invalidBaseURL: return "The upstream base URL is invalid."
        case .invalidResponse: return "Upstream returned a non-HTTP response."
        }
    }
}
