import Foundation
import ContextScopeCore

public struct StreamingParser: Sendable {
    public init() {}

    public func parse<S: AsyncSequence>(
        sseLines: S,
        context: StreamingContext,
        adapter: any ProviderAdapter
    ) -> AsyncStream<TraceEvent> where S.Element == String {
        fatalError("unimplemented")
    }
}
