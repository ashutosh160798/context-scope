public protocol EventSource: Sendable {
    var events: AsyncStream<TraceEvent> { get }
}
