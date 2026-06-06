import Foundation

public struct HTTPRequest: Sendable {
    public let method: String
    public let path: String
    public let headers: [String: String]
    public let body: Data?

    public init(method: String, path: String, headers: [String: String], body: Data?) {
        self.method = method
        self.path = path
        self.headers = headers
        self.body = body
    }
}

public struct HTTPResponse: Sendable {
    public let statusCode: Int
    public let headers: [String: String]
    public let body: Data?

    public init(statusCode: Int, headers: [String: String], body: Data?) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
    }
}

public struct ParsedRequest: Sendable {
    public let model: String
    public let contextItems: [ContextItem]
    public let raw: HTTPRequest

    public init(model: String, contextItems: [ContextItem], raw: HTTPRequest) {
        self.model = model
        self.contextItems = contextItems
        self.raw = raw
    }
}

public struct ParsedResponse: Sendable {
    public let inputTokens: Int?
    public let outputTokens: Int?
    public let raw: HTTPResponse

    public init(inputTokens: Int?, outputTokens: Int?, raw: HTTPResponse) {
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.raw = raw
    }
}

public struct StreamingContext: Sendable {
    public let runID: UUID
    public let model: String

    public init(runID: UUID, model: String) {
        self.runID = runID
        self.model = model
    }
}

public protocol ProviderAdapter: Sendable {
    func canHandle(request: HTTPRequest) -> Bool
    func parseRequest(_ request: HTTPRequest) throws -> ParsedRequest
    func parseResponse(_ response: HTTPResponse, for request: ParsedRequest) throws -> ParsedResponse
    func parseStreamingEvent(_ line: String, context: StreamingContext) throws -> TraceEvent?
}
