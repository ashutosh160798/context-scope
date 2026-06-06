import SwiftUI
import ContextScopeCore

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Status row
            HStack(spacing: 6) {
                Circle()
                    .fill(appState.proxyRunning ? Color.green : Color.secondary.opacity(0.5))
                    .frame(width: 8, height: 8)
                Text(appState.proxyRunning ? "Proxy running" : "Proxy stopped")
                    .font(.caption.bold())
                Spacer()
            }

            if appState.proxyRunning {
                Text(appState.proxyBaseURL)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            Divider()

            // Live token count (visible when proxy is running)
            if appState.proxyRunning, appState.liveTokenCount > 0 {
                HStack {
                    Text("Last request")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(appState.liveTokenCount) tokens")
                        .font(.caption.monospacedDigit().bold())
                }
                Divider()
            }

            // Toggle button
            Button {
                Task { await appState.toggleProxy() }
            } label: {
                Label(
                    appState.proxyRunning ? "Stop Proxy" : "Start Proxy",
                    systemImage: appState.proxyRunning ? "stop.circle" : "play.circle"
                )
                .font(.caption)
            }
            .buttonStyle(.plain)

            Divider()

            Button("Open ContextScope") {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.windows.first?.makeKeyAndOrderFront(nil)
            }
            .font(.caption)
            .buttonStyle(.plain)

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .font(.caption)
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(width: 220)
    }
}
