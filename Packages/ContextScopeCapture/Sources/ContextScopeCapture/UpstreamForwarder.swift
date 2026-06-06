import Foundation
import ContextScopeCore

public actor UpstreamForwarder {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func forward(request: HTTPRequest, to baseURL: URL) async throws -> HTTPResponse {
        fatalError("unimplemented")
    }
}
