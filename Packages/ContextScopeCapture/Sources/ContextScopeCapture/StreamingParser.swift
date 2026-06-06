import Foundation
import ContextScopeCore

public struct StreamingParser: Sendable {
    public init() {}

    public func parse(
        sseLines: some AsyncSequence,
        context: StreamingContext,
        adapter: any ProviderAdapter
    ) -> AsyncStream<TraceEvent> {
        fatalError("unimplemented")
    }
}
