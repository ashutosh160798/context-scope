import Foundation

public enum TraceEventKind: String, Codable, Sendable {
    case requestStart = "request_start"
    case streamChunk = "stream_chunk"
    case toolCall = "tool_call"
    case toolResult = "tool_result"
    case requestComplete = "request_complete"
    case error = "error"
}

public struct TraceEvent: Identifiable, Codable, Sendable {
    public let id: UUID
    public let runID: UUID
    public let kind: TraceEventKind
    public let timestamp: Date
    public let payload: Data

    public init(
        id: UUID = UUID(),
        runID: UUID,
        kind: TraceEventKind,
        timestamp: Date = Date(),
        payload: Data
    ) {
        self.id = id
        self.runID = runID
        self.kind = kind
        self.timestamp = timestamp
        self.payload = payload
    }
}
