import SwiftUI
import AppKit
import ContextScopeCore
import ContextScopeStorage
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
            CommandGroup(after: .saveItem) {
                Button("Import Trace…") {
                    let panel = NSOpenPanel()
                    panel.allowedContentTypes = [.init(filenameExtension: "contextscope.json") ?? .json]
                    panel.allowsMultipleSelection = false
                    panel.canChooseDirectories = false
                    if panel.runModal() == .OK, let url = panel.url {
                        appState.importTrace(from: url)
                    }
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])

                Button("Export Trace…") {
                    guard let data = appState.exportCurrentTrace() else { return }
                    let panel = NSSavePanel()
                    panel.allowedContentTypes = [.init(filenameExtension: "contextscope.json") ?? .json]
                    panel.nameFieldStringValue = "trace.contextscope.json"
                    panel.canCreateDirectories = true
                    if panel.runModal() == .OK, let url = panel.url {
                        try? data.write(to: url)
                    }
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
            }
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

        MenuBarExtra("ContextScope", systemImage: appState.proxyRunning ? "waveform.path.ecg.rectangle.fill" : "waveform.path.ecg.rectangle") {
            MenuBarView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.window)
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
