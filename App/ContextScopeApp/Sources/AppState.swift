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

    // MARK: - Live capture
    @Published var liveSnapshot: ContextSnapshot?
    @Published var liveTokenCount: Int = 0
    private var captureCoordinator: LiveCaptureCoordinator?

    // MARK: - Real sessions (live proxy captures)
    @Published var liveSessions: [Session] = []
    @Published var selectedSession: Session?

    // MARK: - Demo scenarios
    let demoScenarios: [DemoScenario] = DemoScenarioRegistry.all

    private var proxy: ProxyServer?
    private let keychain = KeychainStore()

    init() {
        showOnboarding = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        migrateAPIKeyIfNeeded()
    }

    // One-time migration: move plaintext API key from UserDefaults into Keychain
    private func migrateAPIKeyIfNeeded() {
        let ud = UserDefaults.standard
        if let legacy = ud.string(forKey: "apiKey"), !legacy.isEmpty {
            keychain.write(legacy)
            ud.removeObject(forKey: "apiKey")
        }
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
        let apiKey = keychain.read() ?? ""
        let server = ProxyServer(port: 4319, upstreamBaseURL: upstreamURL, apiKey: apiKey)
        proxy = server
        do {
            try await server.start()
            proxyRunning = true
            proxyError = nil
            let coordinator = LiveCaptureCoordinator()
            captureCoordinator = coordinator
            coordinator.start(events: server.events)
            // Forward coordinator's published values to AppState
            Task { [weak self, weak coordinator] in
                guard let self, let coordinator else { return }
                for await snap in coordinator.$liveSnapshot.values {
                    self.liveSnapshot = snap
                }
            }
            Task { [weak self, weak coordinator] in
                guard let self, let coordinator else { return }
                for await count in coordinator.$liveTokenCount.values {
                    self.liveTokenCount = count
                }
            }
        } catch {
            proxyError = error.localizedDescription
            proxyRunning = false
        }
    }

    func stopProxy() async {
        captureCoordinator?.stop()
        captureCoordinator = nil
        liveSnapshot = nil
        liveTokenCount = 0
        await proxy?.stop()
        proxy = nil
        proxyRunning = false
    }

    // MARK: - Trace import

    /// Load a `.contextscope.json` export file and replay it in the main workspace.
    func importTrace(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let (run, _) = try TraceExporter().import(from: data)
            let snapshot = ContextSnapshot(
                runID: run.id,
                items: run.contextItems,
                totalTokens: run.totalInputTokens,
                contextLimit: nil
            )
            replayEngine = ReplayEngine(frames: [snapshot])
            replayEngine.seek(to: 0)
            activeTab = .contextRiver
            showOnboarding = false
            proxyError = nil
        } catch {
            proxyError = "Import failed: \(error.localizedDescription)"
        }
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
