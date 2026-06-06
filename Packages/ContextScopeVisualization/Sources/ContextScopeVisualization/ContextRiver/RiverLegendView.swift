import SwiftUI
import ContextScopeCore

public struct RiverLegendView: View {
    public let snapshot: ContextSnapshot

    public init(snapshot: ContextSnapshot) {
        self.snapshot = snapshot
    }

    private var lanes: [RiverLane] {
        RiverLayout.lanes(from: snapshot)
    }

    public var body: some View {
        HStack(spacing: 12) {
            ForEach(lanes) { lane in
                if let style = CategoryStyle.styles[lane.id] {
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(style.color)
                            .frame(width: 10, height: 10)
                        Text(style.label)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(tokenLabel(lane.tokenCount))
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            Spacer()
        }
    }

    private func tokenLabel(_ count: Int) -> String {
        count >= 1000 ? "\(count / 1000)k" : "\(count)"
    }
}
