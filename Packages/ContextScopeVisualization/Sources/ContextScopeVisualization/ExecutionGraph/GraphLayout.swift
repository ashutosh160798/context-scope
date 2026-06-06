import Foundation
import ContextScopeCore

public struct GraphNode: Identifiable, Sendable {
    public let id: UUID
    public let event: TraceEvent
    public let column: Int  // left-to-right position in DAG
    public let row: Int     // vertical lane (0 = main, 1+ = tool branches)

    public init(id: UUID = UUID(), event: TraceEvent, column: Int, row: Int) {
        self.id = id
        self.event = event
        self.column = column
        self.row = row
    }
}

public struct GraphEdge: Sendable {
    public let fromID: UUID
    public let toID: UUID

    public init(fromID: UUID, toID: UUID) {
        self.fromID = fromID
        self.toID = toID
    }
}

public struct GraphLayout: Sendable {
    public let nodes: [GraphNode]
    public let edges: [GraphEdge]

    public static func layout(events: [TraceEvent]) -> GraphLayout {
        let sorted = events.sorted { $0.timestamp < $1.timestamp }

        var nodes: [GraphNode] = []
        var edges: [GraphEdge] = []
        var column = 0
        var toolRow = 1
        var lastMainID: UUID? = nil
        var toolCallIDs: [UUID: Int] = [:]  // eventID → row

        for event in sorted {
            let row: Int
            switch event.kind {
            case .toolCall:
                row = toolRow
                toolCallIDs[event.id] = toolRow
                toolRow += 1
            case .toolResult:
                // Same row as its preceding toolCall if we can match; else main
                row = 0
            default:
                row = 0
            }

            let node = GraphNode(id: UUID(), event: event, column: column, row: row)
            nodes.append(node)

            if let prev = lastMainID, row == 0 {
                edges.append(GraphEdge(fromID: prev, toID: node.id))
            }

            if row == 0 {
                lastMainID = node.id
            }
            column += 1
        }

        return GraphLayout(nodes: nodes, edges: edges)
    }

    private init(nodes: [GraphNode], edges: [GraphEdge]) {
        self.nodes = nodes
        self.edges = edges
    }
}
