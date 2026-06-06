import SwiftUI
import ContextScopeCore
import ContextScopeVisualization

struct ContextRiverView: View {
    @EnvironmentObject var appState: AppState
    @State private var animatedLanes: [RiverLane] = []
    @State private var hoveredLaneID: ContextCategory?
    @AccessibilityFocusState private var focused: Bool

    // Prefer live capture data when proxy is running; fall back to replay engine
    private var snapshot: ContextSnapshot? {
        if appState.proxyRunning, let live = appState.liveSnapshot { return live }
        return appState.replayEngine.currentSnapshot
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let snap = snapshot {
                    // Header stats
                    statsHeader(snap)

                    // The river bar
                    riverBar(snap)
                        .accessibilityLabel("Context window usage bar")

                    // Warnings
                    WarningBanners(snapshot: snap)

                    // Per-item breakdown
                    itemList(snap)
                } else {
                    Text("No context snapshot loaded.")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding()
            .animation(.easeInOut(duration: 0.4), value: animatedLanes.map(\.tokenCount))
        }
        .onChange(of: appState.replayEngine.currentFrameIndex) { _, _ in
            updateLanes()
        }
        .onChange(of: appState.liveTokenCount) { _, _ in
            updateLanes()
        }
        .onAppear { updateLanes() }
    }

    // MARK: - Stats header

    @ViewBuilder
    private func statsHeader(_ snap: ContextSnapshot) -> some View {
        HStack(spacing: 24) {
            StatCell(label: "Input Tokens", value: tokenString(snap.totalTokens), estimated: snap.items.allSatisfy(\.estimatedTokenCount))
            if let limit = snap.contextLimit {
                StatCell(label: "Context Limit", value: tokenString(limit), estimated: false)
                StatCell(
                    label: "Pressure",
                    value: snap.pressurePercent.map { String(format: "%.1f%%", $0) } ?? "—",
                    estimated: false,
                    accent: pressureColor(snap.pressurePercent)
                )
                ProgressView(value: min(1.0, Double(snap.totalTokens) / Double(limit)))
                    .progressViewStyle(.linear)
                    .tint(pressureColor(snap.pressurePercent))
                    .frame(maxWidth: 180)
                    .animation(.easeInOut(duration: 0.4), value: snap.totalTokens)
            }
            Spacer()
        }
    }

    // MARK: - River bar

    @ViewBuilder
    private func riverBar(_ snap: ContextSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Context Window")
                .font(.caption.bold())
                .foregroundStyle(.secondary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background (unused capacity)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.primary.opacity(0.06))
                        .frame(height: 44)

                    // Threshold lines
                    if snap.contextLimit != nil {
                        ForEach([0.70, 0.85, 0.95], id: \.self) { threshold in
                            let x = geo.size.width * threshold
                            Rectangle()
                                .fill(thresholdColor(threshold).opacity(0.7))
                                .frame(width: 1, height: 44)
                                .offset(x: x)
                        }
                    }

                    // Category segments
                    HStack(spacing: 2) {
                        ForEach(animatedLanes) { lane in
                            let w = segmentWidth(lane: lane, totalWidth: geo.size.width, contextLimit: snap.contextLimit ?? snap.totalTokens)
                            if w > 0 {
                                laneSegment(lane: lane, width: w, snap: snap)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .frame(height: 44)
                }
            }
            .frame(height: 44)

            // Legend
            RiverLegendView(snapshot: snap)
        }
    }

    @ViewBuilder
    private func laneSegment(lane: RiverLane, width: CGFloat, snap: ContextSnapshot) -> some View {
        let isHovered = hoveredLaneID == lane.id
        let style = CategoryStyle.styles[lane.id]

        Rectangle()
            .fill(style?.color.opacity(isHovered ? 1.0 : 0.80) ?? Color.gray)
            .frame(width: width, height: 44)
            .overlay {
                if width > 40 {
                    Text(style?.label ?? lane.id.rawValue)
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 4)
                }
            }
            .scaleEffect(isHovered ? CGSize(width: 1, height: 1.05) : CGSize(width: 1, height: 1), anchor: .center)
            .onHover { over in
                withAnimation(.easeOut(duration: 0.15)) { hoveredLaneID = over ? lane.id : nil }
            }
            .onTapGesture {
                // Select first item of this category
                if let item = snap.items.first(where: { $0.category == lane.id }) {
                    appState.selectedItem = item
                }
            }
            .help("\(style?.label ?? lane.id.rawValue): \(lane.tokenCount) tokens (\(String(format: "%.1f%%", lane.proportion * 100)) of limit)")
            .transition(.asymmetric(
                insertion: .push(from: .leading).combined(with: .opacity),
                removal: .opacity
            ))
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: width)
            .accessibilityLabel("\(style?.label ?? lane.id.rawValue), \(lane.tokenCount) tokens")
    }

    // MARK: - Item list

    @ViewBuilder
    private func itemList(_ snap: ContextSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Context Items")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)

            ForEach(snap.items) { item in
                ContextItemRow(item: item, totalTokens: snap.contextLimit ?? snap.totalTokens)
                    .onTapGesture { appState.selectedItem = item }
                    .background(appState.selectedItem?.id == item.id ? Color.accentColor.opacity(0.12) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }

    // MARK: - Helpers

    private func updateLanes() {
        guard let snap = snapshot else {
            animatedLanes = []
            return
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
            animatedLanes = RiverLayout.lanes(from: snap)
        }
    }

    private func segmentWidth(lane: RiverLane, totalWidth: CGFloat, contextLimit: Int) -> CGFloat {
        guard contextLimit > 0 else { return 0 }
        let w = totalWidth * CGFloat(lane.tokenCount) / CGFloat(contextLimit)
        return max(0, w)
    }

    private func pressureColor(_ pct: Double?) -> Color {
        guard let pct else { return .accentColor }
        if pct >= 95 { return .red }
        if pct >= 85 { return .orange }
        if pct >= 70 { return .yellow }
        return .green
    }

    private func thresholdColor(_ threshold: Double) -> Color {
        if threshold >= 0.95 { return .red }
        if threshold >= 0.85 { return .orange }
        return .yellow
    }

    private func tokenString(_ n: Int) -> String {
        n >= 1000 ? "\(n / 1000)k" : "\(n)"
    }
}

// MARK: - Supporting views

struct StatCell: View {
    let label: String
    let value: String
    let estimated: Bool
    var accent: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) {
                Text(value)
                    .font(.title3.bold().monospacedDigit())
                    .foregroundStyle(accent)
                if estimated {
                    Text("est.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 4)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 3))
                }
            }
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct ContextItemRow: View {
    let item: ContextItem
    let totalTokens: Int

    private var style: CategoryStyle? { CategoryStyle.styles[item.category] }
    private var pct: Double {
        guard totalTokens > 0 else { return 0 }
        return Double(item.tokenCount) / Double(totalTokens) * 100
    }

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(style?.color ?? .gray)
                .frame(width: 4)
            VStack(alignment: .leading, spacing: 1) {
                HStack {
                    Text(style?.label ?? item.category.rawValue)
                        .font(.caption.bold())
                    if item.estimatedTokenCount {
                        Text("est.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                    Text("\(item.tokenCount) tokens")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f%%", pct))
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.tertiary)
                        .frame(width: 44, alignment: .trailing)
                }
                Text(item.content)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .contentShape(Rectangle())
        .accessibilityLabel("\(style?.label ?? item.category.rawValue), \(item.tokenCount) tokens")
    }
}

// MARK: - Warning banners

struct WarningBanners: View {
    let snapshot: ContextSnapshot

    private var warnings: [String] {
        var result: [String] = []
        if let pct = snapshot.pressurePercent {
            if pct >= 95 { result.append("CRITICAL: Context at \(String(format: "%.0f%%", pct)) capacity. Response may be truncated.") }
            else if pct >= 85 { result.append("WARNING: Context at \(String(format: "%.0f%%", pct)) — nearing limit.") }
            else if pct >= 70 { result.append("NOTICE: Context at \(String(format: "%.0f%%", pct)).") }
        }
        let total = snapshot.totalTokens
        for item in snapshot.items {
            if total > 0 && Double(item.tokenCount) / Double(total) > 0.25 {
                let style = CategoryStyle.styles[item.category]?.label ?? item.category.rawValue
                result.append("'\(style)' consumes \(String(format: "%.0f%%", Double(item.tokenCount) / Double(total) * 100)) of input — consider trimming.")
            }
        }
        // Detect duplicates by category
        var seen: Set<ContextCategory> = []
        for item in snapshot.items {
            if !seen.insert(item.category).inserted {
                let label = CategoryStyle.styles[item.category]?.label ?? item.category.rawValue
                if result.first(where: { $0.contains("duplicate") && $0.contains(label) }) == nil {
                    result.append("Duplicate '\(label)' blocks detected — possible context reconstruction bug.")
                }
            }
        }
        return result
    }

    var body: some View {
        ForEach(warnings, id: \.self) { warning in
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(warning.hasPrefix("CRITICAL") ? .red : warning.hasPrefix("WARNING") ? .orange : .yellow)
                Text(warning)
                    .font(.caption)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.orange.opacity(0.1)))
        }
    }
}
