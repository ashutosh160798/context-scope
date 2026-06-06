import SwiftUI
import ContextScopeCore
import ContextScopeDemoData

struct SessionSidebarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        List(selection: Binding(
            get: { appState.selectedDemoScenario?.id },
            set: { id in
                if let scenario = appState.demoScenarios.first(where: { $0.id == id }) {
                    appState.loadDemoScenario(scenario)
                }
            }
        )) {
            Section("Demo Sessions") {
                ForEach(appState.demoScenarios) { scenario in
                    ScenarioRow(scenario: scenario)
                        .tag(scenario.id)
                }
            }

            if !appState.liveSessions.isEmpty {
                Section("Captured Sessions") {
                    ForEach(appState.liveSessions) { session in
                        Text(session.id.uuidString.prefix(8))
                            .font(.system(.body, design: .monospaced))
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            ProxyStatusBar()
                .environmentObject(appState)
        }
    }
}

struct ScenarioRow: View {
    let scenario: DemoScenario

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(iconColor)
                    .frame(width: 16)
                Text(scenario.displayName)
                    .font(.system(.body))
            }
            Text(scenario.description)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 2)
    }

    private var icon: String {
        switch scenario.id {
        case "healthy_request": return "checkmark.circle.fill"
        case "bloated_context": return "exclamationmark.triangle.fill"
        case "runaway_tool_loop": return "xmark.circle.fill"
        default: return "doc.text.fill"
        }
    }

    private var iconColor: Color {
        switch scenario.id {
        case "healthy_request": return .green
        case "bloated_context": return .orange
        case "runaway_tool_loop": return .red
        default: return .secondary
        }
    }
}

struct ProxyStatusBar: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 4) {
            Divider()
            HStack(spacing: 8) {
                Circle()
                    .fill(appState.proxyRunning ? Color.green : Color.secondary)
                    .frame(width: 8, height: 8)
                VStack(alignment: .leading, spacing: 0) {
                    Text(appState.proxyRunning ? "Proxy Running" : "Proxy Stopped")
                        .font(.caption.bold())
                    if appState.proxyRunning {
                        Text(appState.proxyBaseURL)
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button {
                    Task { await appState.toggleProxy() }
                } label: {
                    Text(appState.proxyRunning ? "Stop" : "Start")
                        .font(.caption.bold())
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
    }
}
