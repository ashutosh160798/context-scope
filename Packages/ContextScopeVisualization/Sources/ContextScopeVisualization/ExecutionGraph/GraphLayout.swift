import Foundation
import ContextScopeCore

public struct GraphNode: Identifiable, Sendable {
    public let id: UUID
    public let event: TraceEvent

    public init(id: UUID = UUID(), event: TraceEvent) {
        self.id = id
        self.event = event
    }
}

public struct GraphLayout: Sendable {
    public static func layout(events: [TraceEvent]) -> [GraphNode] {
        fatalError("unimplemented")
    }
}
