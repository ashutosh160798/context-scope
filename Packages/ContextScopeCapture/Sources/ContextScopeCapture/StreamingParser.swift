import Foundation
import ContextScopeCore

public struct StreamingParser: Sendable {
    public init() {}

    public func parse<S: AsyncSequence & Sendable>(
        sseLines: S,
        context: StreamingContext,
        adapter: any ProviderAdapter
    ) -> AsyncStream<TraceEvent> where S.Element == String {
        AsyncStream { continuation in
            let task = Task {
                do {
                    for try await line in sseLines {
                        if Task.isCancelled { break }
                        if let event = try? adapter.parseStreamingEvent(line, context: context) {
                            continuation.yield(event)
                        }
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
