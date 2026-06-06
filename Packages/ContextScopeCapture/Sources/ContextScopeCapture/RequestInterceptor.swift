import Foundation
import ContextScopeCore

public actor RequestInterceptor {
    private let adapters: AdapterRegistry
    private let classifier: ContextClassifier

    public init(adapters: AdapterRegistry = .openAI(), classifier: ContextClassifier = ContextClassifier()) {
        self.adapters = adapters
        self.classifier = classifier
    }

    public func intercept(request: HTTPRequest) async throws -> ParsedRequest {
        guard let adapter = adapters.adapter(for: request) else {
            throw InterceptorError.noAdapterFound(request.path)
        }
        return try adapter.parseRequest(request)
    }
}

public enum InterceptorError: Error, LocalizedError {
    case noAdapterFound(String)

    public var errorDescription: String? {
        switch self {
        case .noAdapterFound(let path):
            return "No adapter found for path '\(path)'."
        }
    }
}
