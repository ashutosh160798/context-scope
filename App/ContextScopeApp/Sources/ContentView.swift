import SwiftUI
import ContextScopeCore
import ContextScopeDemoData

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationSplitView {
            SessionSidebarView()
                .environmentObject(appState)
                .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 300)
        } content: {
            WorkspaceView()
                .environmentObject(appState)
                .navigationSplitViewColumnWidth(min: 500, ideal: 720)
        } detail: {
            InspectorView()
                .environmentObject(appState)
                .navigationSplitViewColumnWidth(min: 260, ideal: 300, max: 400)
        }
        .navigationTitle("ContextScope")
    }
}
