import SwiftUI
import ContextScopeCore
import ContextScopeVisualization

struct WorkspaceView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Tab picker
            HStack {
                Picker("", selection: $appState.activeTab) {
                    ForEach(WorkspaceTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 500)
                Spacer()
                if let session = appState.selectedDemoSession {
                    modelBadge(session.model)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Content
            Group {
                switch appState.activeTab {
                case .contextRiver:
                    ContextRiverView()
                        .environmentObject(appState)
                case .executionGraph:
                    ExecutionGraphView()
                        .environmentObject(appState)
                case .timelineReplay:
                    TimelineReplayView()
                        .environmentObject(appState)
                case .rawRequest:
                    RawRequestView()
                        .environmentObject(appState)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(.background)
        .overlay {
            if appState.selectedDemoSession == nil && !appState.proxyRunning {
                EmptyStateView()
                    .environmentObject(appState)
            }
        }
    }

    @ViewBuilder
    private func modelBadge(_ model: String) -> some View {
        Text(model)
            .font(.caption.monospacedDigit())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct EmptyStateView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("See exactly what your AI sees.")
                .font(.title2.bold())
            Text("Load a demo session or start the proxy and send a request.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 12) {
                Button("Play Demo") {
                    appState.startDemo()
                }
                .buttonStyle(.borderedProminent)
                Button("Set Up Proxy") {
                    appState.showOnboarding = true
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(40)
        .frame(maxWidth: 400)
    }
}
