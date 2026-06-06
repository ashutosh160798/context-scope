import SwiftUI
import ContextScopeCore
import ContextScopeVisualization

struct TimelineReplayView: View {
    @EnvironmentObject var appState: AppState
    @State private var playbackSpeed: Double = 1.0
    @State private var playTask: Task<Void, Never>?

    private var engine: ReplayEngine { appState.replayEngine }

    var body: some View {
        VStack(spacing: 0) {
            // Main replay area (same river view driven by replay engine)
            ContextRiverView()
                .environmentObject(appState)

            Divider()

            // Timeline scrubber + controls
            VStack(spacing: 12) {
                // Frame thumbnails / timeline
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(frameSummaries.enumerated()), id: \.offset) { idx, summary in
                            FrameThumbnail(summary: summary, index: idx, isSelected: engine.currentFrameIndex == idx)
                                .onTapGesture { engine.seek(to: idx) }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 72)

                // Scrubber
                HStack(spacing: 12) {
                    Text("Frame \(engine.currentFrameIndex + 1) of \(engine.frameCount)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 100, alignment: .leading)

                    Slider(
                        value: Binding(
                            get: { engine.progress },
                            set: { engine.seek(to: Int(($0 * Double(engine.frameCount - 1)).rounded())) }
                        ),
                        in: 0...1
                    )

                    if let snap = engine.currentSnapshot {
                        Text(tokenLabel(snap.totalTokens))
                            .font(.caption.monospacedDigit().bold())
                            .foregroundStyle(.secondary)
                            .frame(width: 60, alignment: .trailing)
                    }
                }
                .padding(.horizontal)

                // Playback controls
                HStack(spacing: 16) {
                    Button(action: { engine.restart() }) {
                        Image(systemName: "backward.end.fill")
                    }
                    Button(action: { engine.stepBackward() }) {
                        Image(systemName: "backward.frame.fill")
                    }
                    Button(action: { togglePlay() }) {
                        Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                            .frame(width: 24)
                    }
                    .buttonStyle(.borderedProminent)
                    Button(action: { engine.stepForward() }) {
                        Image(systemName: "forward.frame.fill")
                    }
                    Button(action: { engine.seek(to: engine.frameCount - 1) }) {
                        Image(systemName: "forward.end.fill")
                    }

                    Divider().frame(height: 20)

                    Text("Speed:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("", selection: $playbackSpeed) {
                        Text("0.5×").tag(0.5)
                        Text("1×").tag(1.0)
                        Text("2×").tag(2.0)
                        Text("4×").tag(4.0)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 160)
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
            .background(.background)
        }
    }

    private var frameSummaries: [(tokens: Int, pct: Double?)] {
        guard let session = appState.selectedDemoSession else { return [] }
        return session.frames.map { ($0.totalTokens, $0.pressurePercent) }
    }

    private func togglePlay() {
        if engine.isPlaying {
            engine.pause()
            playTask?.cancel()
        } else {
            let speed = playbackSpeed
            playTask = Task { @MainActor in
                await engine.play(speed: speed)
            }
        }
    }

    private func tokenLabel(_ n: Int) -> String {
        n >= 1000 ? "\(n / 1000)k tok" : "\(n) tok"
    }
}

struct FrameThumbnail: View {
    let summary: (tokens: Int, pct: Double?)
    let index: Int
    let isSelected: Bool

    private var barColor: Color {
        guard let pct = summary.pct else { return .accentColor }
        if pct >= 95 { return .red }
        if pct >= 85 { return .orange }
        if pct >= 70 { return .yellow }
        return .green
    }

    private var barHeight: CGFloat {
        let pct = summary.pct ?? 1.0
        return max(4, CGFloat(pct) / 100.0 * 44)
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.primary.opacity(0.07))
                    .frame(width: 32, height: 44)
                RoundedRectangle(cornerRadius: 3)
                    .fill(barColor.opacity(0.8))
                    .frame(width: 32, height: barHeight)
            }
            Text("\(index + 1)")
                .font(.system(size: 9).monospacedDigit())
                .foregroundStyle(.tertiary)
        }
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: 4)
                    .strokeBorder(Color.accentColor, lineWidth: 2)
            }
        }
        .contentShape(Rectangle())
        .accessibilityLabel("Frame \(index + 1), \(summary.tokens) tokens")
    }
}
