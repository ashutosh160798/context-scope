import Foundation
import Network
import os.log
import ContextScopeCore

public actor ProxyServer {
    public let port: UInt16
    public private(set) var upstreamBaseURL: URL
    public private(set) var apiKey: String

    private var listener: NWListener?
    private let logger = Logger(subsystem: "com.contextscope.capture", category: "ProxyServer")
    private let interceptor: RequestInterceptor
    private let sanitizer: Sanitizer
    private let eventContinuation: AsyncStream<TraceEvent>.Continuation
    public nonisolated let events: AsyncStream<TraceEvent>

    public init(port: UInt16 = 4319, upstreamBaseURL: URL, apiKey: String) {
        self.port = port
        self.upstreamBaseURL = upstreamBaseURL
        self.apiKey = apiKey
        self.interceptor = RequestInterceptor()
        self.sanitizer = Sanitizer()

        var cont: AsyncStream<TraceEvent>.Continuation!
        self.events = AsyncStream { cont = $0 }
        self.eventContinuation = cont
    }

    public func updateUpstream(baseURL: URL, apiKey: String) {
        self.upstreamBaseURL = baseURL
        self.apiKey = apiKey
    }

    public func start() async throws {
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true

        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            throw ProxyError.invalidPort(port)
        }

        let l = try NWListener(using: params, on: nwPort)
        self.listener = l

        let baseURL = self.upstreamBaseURL
        let key = self.apiKey
        let cont = self.eventContinuation
        let log = self.logger

        l.newConnectionHandler = { connection in
            Task {
                await ProxyServer.handleConnection(
                    connection,
                    upstreamBaseURL: baseURL,
                    apiKey: key,
                    eventContinuation: cont,
                    logger: log
                )
            }
        }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            // Clear the handler immediately after the first meaningful state to
            // prevent double-resume when stop() causes a subsequent .cancelled.
            l.stateUpdateHandler = { [weak l] state in
                switch state {
                case .ready:
                    l?.stateUpdateHandler = { _ in }
                    continuation.resume()
                case .failed(let error):
                    l?.stateUpdateHandler = { _ in }
                    continuation.resume(throwing: error)
                default:
                    break
                }
            }
            l.start(queue: .global(qos: .userInitiated))
        }
        logger.info("Proxy listening on 127.0.0.1:\(self.port)")
    }

    public func stop() async {
        listener?.cancel()
        listener = nil
        logger.info("Proxy stopped")
    }

    // Static to avoid actor isolation issues in the closure
    private static func handleConnection(
        _ connection: NWConnection,
        upstreamBaseURL: URL,
        apiKey: String,
        eventContinuation: AsyncStream<TraceEvent>.Continuation,
        logger: Logger
    ) async {
        connection.start(queue: .global(qos: .userInitiated))
        defer { connection.cancel() }

        do {
            guard let requestData = try await readHTTPMessage(from: connection) else { return }
            guard let parsed = HTTPRequestParser.parse(requestData) else {
                await send(simpleResponse(status: 400, body: "Bad Request"), to: connection)
                return
            }

            // Health check
            if parsed.path == "/health" {
                await send(simpleResponse(status: 200, body: #"{"status":"ok"}"#), to: connection)
                return
            }

            // Inject authorization header
            var headers = parsed.headers
            headers["Authorization"] = "Bearer \(apiKey)"
            headers["Content-Type"] = "application/json"
            let request = HTTPRequest(method: parsed.method, path: parsed.path, headers: headers, body: parsed.body)

            let runID = UUID()
            let isStreaming = parsed.body.flatMap {
                (try? JSONSerialization.jsonObject(with: $0) as? [String: Any])
            }?["stream"] as? Bool ?? false

            eventContinuation.yield(TraceEvent(runID: runID, kind: .requestStart, payload: parsed.body ?? Data()))

            let forwarder = UpstreamForwarder()

            if isStreaming {
                let responseHeadersSent = Box(false)
                let allChunks = Box(Data())

                let finalResponse = try await forwarder.forwardStreaming(
                    request: request,
                    to: upstreamBaseURL
                ) { chunk in
                    allChunks.value.append(chunk)
                    if !responseHeadersSent.value {
                        let header = "HTTP/1.1 200 OK\r\nContent-Type: text/event-stream\r\nCache-Control: no-cache\r\nTransfer-Encoding: chunked\r\nConnection: keep-alive\r\n\r\n"
                        await send(Data(header.utf8), to: connection)
                        responseHeadersSent.value = true
                    }
                    // Send chunk in HTTP chunked encoding format
                    let hexLen = String(chunk.count, radix: 16)
                    var chunkData = Data()
                    chunkData.append(Data((hexLen + "\r\n").utf8))
                    chunkData.append(chunk)
                    chunkData.append(Data("\r\n".utf8))
                    await send(chunkData, to: connection)

                    // Parse SSE event for tracing
                    if let line = String(data: chunk, encoding: .utf8) {
                        if line.hasPrefix("data: ") {
                            let adapter = OpenAIAdapter()
                            let ctx = StreamingContext(runID: runID, model: "unknown")
                            if let event = try? adapter.parseStreamingEvent(line.trimmingCharacters(in: .newlines), context: ctx) {
                                eventContinuation.yield(event)
                            }
                        }
                    }
                }

                // Send final chunk
                await send(Data("0\r\n\r\n".utf8), to: connection)
                _ = finalResponse

            } else {
                let response = try await forwarder.forward(request: request, to: upstreamBaseURL)
                var responseData = Data()
                let statusLine = "HTTP/1.1 \(response.statusCode) OK\r\n"
                responseData.append(Data(statusLine.utf8))
                for (key, value) in response.headers {
                    responseData.append(Data("\(key): \(value)\r\n".utf8))
                }
                if let body = response.body {
                    responseData.append(Data("Content-Length: \(body.count)\r\n\r\n".utf8))
                    responseData.append(body)
                } else {
                    responseData.append(Data("\r\n".utf8))
                }
                await send(responseData, to: connection)

                eventContinuation.yield(TraceEvent(runID: runID, kind: .requestComplete, payload: response.body ?? Data()))
            }

        } catch {
            logger.error("Connection error: \(error.localizedDescription)")
            await send(simpleResponse(status: 502, body: "Bad Gateway"), to: connection)
        }
    }

    private static func readHTTPMessage(from connection: NWConnection) async throws -> Data? {
        var accumulated = Data()
        let maxSize = 16 * 1024 * 1024  // 16 MB

        while accumulated.count < maxSize {
            let chunk = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Data, Error>) in
                connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isComplete, error in
                    if let error = error {
                        cont.resume(throwing: error)
                    } else {
                        cont.resume(returning: data ?? Data())
                    }
                }
            }

            if chunk.isEmpty { break }
            accumulated.append(chunk)

            if let headerEnd = accumulated.range(of: Data("\r\n\r\n".utf8)) {
                let headerSection = String(data: accumulated[..<headerEnd.lowerBound], encoding: .utf8) ?? ""
                let bodyStart = headerEnd.upperBound

                var contentLength = 0
                for line in headerSection.components(separatedBy: "\r\n") {
                    if line.lowercased().hasPrefix("content-length:") {
                        let val = line.dropFirst("content-length:".count).trimmingCharacters(in: .whitespaces)
                        contentLength = Int(val) ?? 0
                    }
                }

                let totalNeeded = bodyStart + contentLength
                if accumulated.count >= totalNeeded { break }
            }
        }

        return accumulated.isEmpty ? nil : accumulated
    }

    private static func send(_ data: Data, to connection: NWConnection) async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            connection.send(content: data, completion: .contentProcessed { _ in cont.resume() })
        }
    }

    private static func simpleResponse(status: Int, body: String) -> Data {
        let bodyData = Data(body.utf8)
        let header = "HTTP/1.1 \(status) \(httpStatus(status))\r\nContent-Type: application/json\r\nContent-Length: \(bodyData.count)\r\nConnection: close\r\n\r\n"
        return Data(header.utf8) + bodyData
    }

    private static func httpStatus(_ code: Int) -> String {
        switch code {
        case 200: return "OK"
        case 400: return "Bad Request"
        case 404: return "Not Found"
        case 502: return "Bad Gateway"
        default: return "Unknown"
        }
    }
}

// Reference-type wrapper used to carry mutable state across @Sendable closures
// without unsafe escapes. The mutations are safe because the closure is called
// sequentially by the `for try await` loop in `forwardStreaming`.
private final class Box<T>: @unchecked Sendable {
    var value: T
    init(_ value: T) { self.value = value }
}

public enum ProxyError: Error, LocalizedError {
    case invalidPort(UInt16)
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .invalidPort(let p): return "Invalid port: \(p)"
        case .cancelled: return "Listener was cancelled."
        }
    }
}

// Minimal HTTP/1.1 request parser
private struct ParsedHTTPRequest {
    let method: String
    let path: String
    let headers: [String: String]
    let body: Data?
}

private enum HTTPRequestParser {
    static func parse(_ data: Data) -> ParsedHTTPRequest? {
        guard let text = String(data: data, encoding: .utf8) else { return nil }
        guard let headerBodyRange = text.range(of: "\r\n\r\n") else { return nil }

        let headerSection = String(text[..<headerBodyRange.lowerBound])
        let bodyString = String(text[headerBodyRange.upperBound...])
        let bodyData = bodyString.isEmpty ? nil : Data(bodyString.utf8)

        var lines = headerSection.components(separatedBy: "\r\n")
        guard let requestLine = lines.first else { return nil }
        lines.removeFirst()

        let parts = requestLine.split(separator: " ", maxSplits: 2).map(String.init)
        guard parts.count >= 2 else { return nil }

        var headers: [String: String] = [:]
        for line in lines {
            if let colonIdx = line.firstIndex(of: ":") {
                let key = String(line[..<colonIdx]).trimmingCharacters(in: .whitespaces)
                let value = String(line[line.index(after: colonIdx)...]).trimmingCharacters(in: .whitespaces)
                headers[key] = value
            }
        }

        return ParsedHTTPRequest(method: parts[0], path: parts[1], headers: headers, body: bodyData)
    }
}
