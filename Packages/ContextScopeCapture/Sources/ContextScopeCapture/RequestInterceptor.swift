import Foundation
import ContextScopeCore

public actor RequestInterceptor {
    private let adapters: AdapterRegistry
    private let classifier: ContextClassifier

    public init(adapters: AdapterRegistry, classifier: ContextClassifier) {
        self.adapters = adapters
        self.classifier = classifier
    }

    public func intercept(request: HTTPRequest) async throws -> ParsedRequest {
        fatalError("unimplemented")
    }
}
