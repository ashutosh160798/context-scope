import ContextScopeCore

public struct AdapterRegistry: Sendable {
    private let adapters: [any ProviderAdapter]

    public init(adapters: [any ProviderAdapter] = []) {
        self.adapters = adapters
    }

    public func adapter(for request: HTTPRequest) -> (any ProviderAdapter)? {
        adapters.first { $0.canHandle(request: request) }
    }
}
