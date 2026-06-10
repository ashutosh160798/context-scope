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

    // MARK: - Persistence
    private var db: Database?
    private var sessionRepo: SessionRepository?
    private var runRepo: RunRepository?
    private var currentSession: Session?
    private let projectID: UUID = {
        let key = "com.contextscope.projectID"
        if let s = UserDefaults.standard.string(forKey: key), let id = UUID(uuidString: s) { return id }
        let id = UUID()
        UserDefaults.standard.set(id.uuidString, forKey: key)
        return id
    }()

    private static func storageURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("ContextScope", isDirectory: true)
    }

    init() {
        showOnboarding = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        migrateAPIKeyIfNeeded()
        Task { await self.setupStorage() }
    }

    // One-time migration: move plaintext API key from UserDefaults into Keychain
    private func migrateAPIKeyIfNeeded() {
        let ud = UserDefaults.standard
        if let legacy = ud.string(forKey: "apiKey"), !legacy.isEmpty {
            keychain.write(legacy)
            ud.removeObject(forKey: "apiKey")
        }
    }

    private func setupStorage() async {
        let database = Database(url: Self.storageURL())
        do {
            try await database.open()
            try await database.migrate()
            db = database
            sessionRepo = SessionRepository(database: database)
            runRepo = RunRepository(database: database)
            let stored = (try? await sessionRepo!.fetchSessions(for: projectID)) ?? []
            liveSessions = stored.sorted { $0.startedAt > $1.startedAt }
        } catch {
            // Non-fatal: the app works without persistence, just loses data on quit.
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

            // Start a new session for this proxy run
            let session = Session(projectID: projectID)
            currentSession = session
            if let repo = sessionRepo {
                try? await repo.save(session)
                liveSessions.insert(session, at: 0)
            }

            let coordinator = LiveCaptureCoordinator()
            captureCoordinator = coordinator

            // Save each completed run to the repository
            coordinator.onRunComplete = { [weak self] snapshot, model, inputItems in
                guard let self, let runRepo = self.runRepo, let session = self.currentSession else { return }
                Task {
                    let outputItem = snapshot.items.last { $0.category == .toolOutputs }
                    let outputTokens = outputItem?.tokenCount ?? 0
                    let inputTokens = max(0, snapshot.totalTokens - outputTokens)
                    let isEstimated = inputItems.isEmpty || inputItems.allSatisfy { $0.estimatedTokenCount }
                    let run = Run(
                        id: snapshot.runID,
                        sessionID: session.id,
                        model: model,
                        requestedAt: snapshot.timestamp,
                        contextItems: inputItems,
                        totalInputTokens: inputTokens,
                        totalOutputTokens: outputTokens,
                        inputTokensEstimated: isEstimated
                    )
                    try? await runRepo.save(run)
                }
            }

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

        // Mark session as ended
        if var session = currentSession {
            session.endedAt = Date()
            currentSession = nil
            if let repo = sessionRepo {
                try? await repo.save(session)
                if let idx = liveSessions.firstIndex(where: { $0.id == session.id }) {
                    liveSessions[idx] = session
                }
            }
        }

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
