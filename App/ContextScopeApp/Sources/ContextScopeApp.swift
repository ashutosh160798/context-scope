import SwiftUI
import ContextScopeCore
import ContextScopeDemoData

@main
struct ContextScopeApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .frame(minWidth: 1100, minHeight: 700)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandMenu("Proxy") {
                Button(appState.proxyRunning ? "Stop Proxy" : "Start Proxy") {
                    Task { await appState.toggleProxy() }
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])

                Divider()

                Button("Copy Base URL") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(appState.proxyBaseURL, forType: .string)
                }
            }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        if appState.showOnboarding {
            OnboardingView()
                .environmentObject(appState)
        } else {
            ContentView()
                .environmentObject(appState)
        }
    }
}
