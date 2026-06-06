import Foundation
import SwiftUI
import ContextScopeCore
import ContextScopeCapture
import ContextScopeStorage
import ContextScopeDemoData
import ContextScopeVisualization

@MainActor
final class AppState: ObservableObject {
    // MARK: - Navigation state
    @Published var showOnboarding: Bool
    @Published var selectedDemoScenario: DemoScenario?
    @Published var selectedDemoSession: DemoSession?
    @Published var selectedItem: ContextItem?
    @Published var activeTab: WorkspaceTab = .contextRiver

    // MARK: - Replay
    @Published var replayEngine: ReplayEngine = ReplayEngine(frames: [])

    // MARK: - Proxy
    @Published var proxyRunning: Bool = false
    @Published var proxyError: String?
    var proxyBaseURL: String { "http://127.0.0.1:4319/v1" }

    // MARK: - Real sessions (live proxy captures)
    @Published var liveSessions: [Session] = []
    @Published var selectedSession: Session?

    // MARK: - Demo scenarios
    let demoScenarios: [DemoScenario] = DemoScenarioRegistry.all

    private var proxy: ProxyServer?

    init() {
        // Show onboarding on first launch
        showOnboarding = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
    }

    // MARK: - Demo

    func loadDemoScenario(_ scenario: DemoScenario) {
        selectedDemoScenario = scenario
        do {
            let session = try DemoScenarioRegistry.load(scenario: scenario)
            selectedDemoSession = session
            replayEngine = ReplayEngine(frames: session.frames)
            replayEngine.seek(to: 0)
            activeTab = .contextRiver
            showOnboarding = false
        } catch {
            proxyError = error.localizedDescription
        }
    }

    func startDemo() {
        let first = demoScenarios.first ?? demoScenarios[0]
        loadDemoScenario(first)
    }

    // MARK: - Proxy lifecycle

    func toggleProxy() async {
        if proxyRunning {
            await stopProxy()
        } else {
            await startProxy()
        }
    }

    func startProxy() async {
        guard !proxyRunning else { return }
        let upstreamURL = URL(string: UserDefaults.standard.string(forKey: "upstreamBaseURL") ?? "https://api.openai.com")!
        let apiKey = UserDefaults.standard.string(forKey: "apiKey") ?? ""
        let server = ProxyServer(port: 4319, upstreamBaseURL: upstreamURL, apiKey: apiKey)
        proxy = server
        do {
            try await server.start()
            proxyRunning = true
            proxyError = nil
        } catch {
            proxyError = error.localizedDescription
            proxyRunning = false
        }
    }

    func stopProxy() async {
        await proxy?.stop()
        proxy = nil
        proxyRunning = false
    }

    // MARK: - Onboarding

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        showOnboarding = false
    }
}

enum WorkspaceTab: String, CaseIterable {
    case contextRiver = "Context River"
    case executionGraph = "Execution Graph"
    case timelineReplay = "Timeline Replay"
    case rawRequest = "Raw Request"
}
