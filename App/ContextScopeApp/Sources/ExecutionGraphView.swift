import SwiftUI
import ContextScopeCore
import ContextScopeVisualization

struct ExecutionGraphView: View {
    @EnvironmentObject var appState: AppState

    private var syntheticEvents: [TraceEvent] {
        guard let session = appState.selectedDemoSession else { return [] }
        let runID = session.frames.first?.runID ?? UUID()
        var events: [TraceEvent] = []
        let base = Date()

        events.append(TraceEvent(runID: runID, kind: .requestStart, timestamp: base, payload: Data()))

        for (i, frame) in session.frames.enumerated() {
            let t = base.addingTimeInterval(Double(i) * 1.5)
            if frame.items.contains(where: { $0.category == .toolOutputs }) {
                events.append(TraceEvent(runID: runID, kind: .toolCall, timestamp: t, payload: Data()))
                events.append(TraceEvent(runID: runID, kind: .toolResult, timestamp: t.addingTimeInterval(0.5), payload: Data()))
            }
            if i == session.frames.count - 1 {
                events.append(TraceEvent(runID: runID, kind: .requestComplete, timestamp: t.addingTimeInterval(1.0), payload: Data()))
            }
        }
        return events
    }

    private var layout: GraphLayout { GraphLayout.layout(events: syntheticEvents) }
    private let nodeWidth: CGFloat = 120
    private let nodeHeight: CGFloat = 44
    private let colSpacing: CGFloat = 160
    private let rowSpacing: CGFloat = 70

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            ZStack(alignment: .topLeading) {
                // Edges
                ForEach(layout.edges, id: \.fromID) { edge in
                    if let from = layout.nodes.first(where: { $0.id == edge.fromID }),
                       let to = layout.nodes.first(where: { $0.id == edge.toID }) {
                        EdgeLine(from: nodeCenter(from), to: nodeCenter(to))
                    }
                }
                // Nodes
                ForEach(layout.nodes) { node in
                    GraphNodeView(node: node, isActive: isActive(node))
                        .frame(width: nodeWidth, height: nodeHeight)
                        .position(nodeCenter(node))
                }
            }
            .frame(
                width: CGFloat((layout.nodes.map(\.column).max() ?? 0) + 1) * colSpacing + 80,
                height: CGFloat((layout.nodes.map(\.row).max() ?? 0) + 1) * rowSpacing + 80
            )
            .padding(40)
        }
    }

    private func nodeCenter(_ node: GraphNode) -> CGPoint {
        CGPoint(
            x: CGFloat(node.column) * colSpacing + nodeWidth / 2 + 40,
            y: CGFloat(node.row) * rowSpacing + nodeHeight / 2 + 40
        )
    }

    private func isActive(_ node: GraphNode) -> Bool {
        guard let snap = appState.replayEngine.currentSnapshot else { return false }
        // Mark nodes as active based on replay frame timing
        return node.event.timestamp <= snap.timestamp
    }
}

struct GraphNodeView: View {
    let node: GraphNode
    let isActive: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.bold())
                .foregroundStyle(iconColor)
            Text(label)
                .font(.caption.bold())
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isActive ? iconColor.opacity(0.15) : Color.primary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isActive ? iconColor : Color.primary.opacity(0.15), lineWidth: isActive ? 1.5 : 1)
                )
        )
        .opacity(isActive ? 1.0 : 0.5)
        .animation(.easeInOut(duration: 0.3), value: isActive)
    }

    private var label: String {
        switch node.event.kind {
        case .requestStart: return "Request"
        case .streamChunk: return "Streaming"
        case .toolCall: return "Tool Call"
        case .toolResult: return "Tool Result"
        case .requestComplete: return "Complete"
        case .error: return "Error"
        }
    }

    private var icon: String {
        switch node.event.kind {
        case .requestStart: return "arrow.up.circle.fill"
        case .streamChunk: return "waveform"
        case .toolCall: return "function"
        case .toolResult: return "checkmark.circle"
        case .requestComplete: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        }
    }

    private var iconColor: Color {
        switch node.event.kind {
        case .requestStart: return .blue
        case .streamChunk: return .teal
        case .toolCall: return .orange
        case .toolResult: return .purple
        case .requestComplete: return .green
        case .error: return .red
        }
    }
}

struct EdgeLine: View {
    let from: CGPoint
    let to: CGPoint

    var body: some View {
        Path { p in
            p.move(to: from)
            let midX = (from.x + to.x) / 2
            p.addCurve(to: to, control1: CGPoint(x: midX, y: from.y), control2: CGPoint(x: midX, y: to.y))
        }
        .stroke(Color.primary.opacity(0.2), style: StrokeStyle(lineWidth: 1.5, dash: []))
    }
}
