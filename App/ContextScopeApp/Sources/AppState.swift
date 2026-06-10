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
    @Published var lastLatencyMs: Double?
    @Published private(set) var lastCompletedRun: Run?
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

            // Save each completed run and cache it for export
            coordinator.onRunComplete = { [weak self] snapshot, model, inputItems in
                guard let self else { return }
                let outputItem = snapshot.items.last { $0.category == .toolOutputs }
                let outputTokens = outputItem?.tokenCount ?? 0
                let inputTokens = max(0, snapshot.totalTokens - outputTokens)
                let isEstimated = inputItems.isEmpty || inputItems.allSatisfy { $0.estimatedTokenCount }
                let run = Run(
                    id: snapshot.runID,
                    sessionID: self.currentSession?.id ?? UUID(),
                    model: model,
                    requestedAt: snapshot.timestamp,
                    contextItems: inputItems,
                    totalInputTokens: inputTokens,
                    totalOutputTokens: outputTokens,
                    inputTokensEstimated: isEstimated
                )
                self.lastCompletedRun = run
                if let runRepo = self.runRepo {
                    Task { try? await runRepo.save(run) }
                }
            }

            coordinator.onLatencyMeasured = { [weak self] latency in
                self?.lastLatencyMs = latency * 1_000
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
        lastLatencyMs = nil

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

    /// Build export data for the most recent completed run, or the current
    /// snapshot if no run has completed yet (e.g. demo mode). Returns nil
    /// when there is nothing to export.
    func exportCurrentTrace() -> Data? {
        let run: Run
        if let completed = lastCompletedRun {
            run = completed
        } else if let snapshot = liveSnapshot ?? replayEngine.currentSnapshot {
            run = Run(
                id: snapshot.runID,
                sessionID: currentSession?.id ?? UUID(),
                model: "unknown",
                requestedAt: snapshot.timestamp,
                contextItems: snapshot.items,
                totalInputTokens: snapshot.totalTokens,
                inputTokensEstimated: true
            )
        } else {
            return nil
        }
        return try? TraceExporter().export(run: run, events: [])
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
