import XCTest
@testable import ContextScopeStorage
import ContextScopeCore

final class ContextScopeStorageTests: XCTestCase {
    private var tempURL: URL!
    private var db: Database!
    private var sessionRepo: SessionRepository!
    private var runRepo: RunRepository!

    override func setUp() async throws {
        try await super.setUp()
        tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("ContextScopeTests-\(UUID().uuidString)", isDirectory: true)
        db = Database(url: tempURL)
        try await db.open()
        sessionRepo = SessionRepository(database: db)
        runRepo = RunRepository(database: db)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempURL)
        try await super.tearDown()
    }

    // MARK: - Session round-trips

    func testSessionSaveAndFetch() async throws {
        let projectID = UUID()
        let session = Session(projectID: projectID)
        try await sessionRepo.save(session)
        let fetched = try await sessionRepo.fetchSessions(for: projectID)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, session.id)
        XCTAssertEqual(fetched.first?.projectID, projectID)
    }

    func testSessionUpdatePreservesID() async throws {
        let projectID = UUID()
        var session = Session(projectID: projectID)
        try await sessionRepo.save(session)
        session.endedAt = Date()
        try await sessionRepo.save(session)
        let fetched = try await sessionRepo.fetchSessions(for: projectID)
        XCTAssertEqual(fetched.count, 1, "Update must not duplicate the session")
        XCTAssertNotNil(fetched.first?.endedAt)
    }

    func testSessionDeleteRemovesIt() async throws {
        let projectID = UUID()
        let session = Session(projectID: projectID)
        try await sessionRepo.save(session)
        try await sessionRepo.deleteSession(id: session.id)
        let fetched = try await sessionRepo.fetchSessions(for: projectID)
        XCTAssertTrue(fetched.isEmpty)
    }

    func testFetchSessionsForDifferentProjectReturnsEmpty() async throws {
        let session = Session(projectID: UUID())
        try await sessionRepo.save(session)
        let other = try await sessionRepo.fetchSessions(for: UUID())
        XCTAssertTrue(other.isEmpty)
    }

    // MARK: - Run round-trips

    func testRunSaveAndFetch() async throws {
        let sessionID = UUID()
        let run = Run(
            sessionID: sessionID,
            model: "gpt-4o",
            contextItems: [ContextItem(category: .systemPrompt, tokenCount: 50,
                                       estimatedTokenCount: false, content: "sys")],
            totalInputTokens: 50,
            inputTokensEstimated: false
        )
        try await runRepo.save(run)
        let fetched = try await runRepo.fetchRuns(for: sessionID)
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.id, run.id)
        XCTAssertEqual(fetched.first?.model, "gpt-4o")
    }

    func testRunDeleteRemovesIt() async throws {
        let sessionID = UUID()
        let run = Run(sessionID: sessionID, model: "gpt-4o-mini", contextItems: [],
                      totalInputTokens: 0, inputTokensEstimated: true)
        try await runRepo.save(run)
        try await runRepo.deleteRun(id: run.id)
        let fetched = try await runRepo.fetchRuns(for: sessionID)
        XCTAssertTrue(fetched.isEmpty)
    }

    func testRunsForDifferentSessionNotReturned() async throws {
        let run = Run(sessionID: UUID(), model: "gpt-4o", contextItems: [],
                      totalInputTokens: 0, inputTokensEstimated: true)
        try await runRepo.save(run)
        let other = try await runRepo.fetchRuns(for: UUID())
        XCTAssertTrue(other.isEmpty)
    }

    // MARK: - TraceExporter redaction
    // Note: TraceEvent.payload is Codable `Data` — it is base64-encoded in the
    // JSON file. We verify redaction by round-tripping through import() so we
    // read the actual decoded payload bytes rather than the base64 envelope.

    func testExportRedactsBearerToken() throws {
        let run = Run(sessionID: UUID(), model: "gpt-4o", contextItems: [],
                      totalInputTokens: 0, inputTokensEstimated: true)
        let raw = #"{"role":"user","content":"use key Bearer sk-abc12345678901234567890XXXXX please"}"#
        let event = TraceEvent(runID: run.id, kind: .requestStart, payload: Data(raw.utf8))
        let exported = try TraceExporter().export(run: run, events: [event])
        let (_, events) = try TraceExporter().import(from: exported)
        let text = String(data: events.first?.payload ?? Data(), encoding: .utf8) ?? ""
        XCTAssertFalse(text.contains("sk-abc12345678901234567890XXXXX"), "Bearer key must be redacted")
        XCTAssertTrue(text.contains("[REDACTED]"))
    }

    func testExportPreservesNonSecretContent() throws {
        let run = Run(sessionID: UUID(), model: "gpt-4o", contextItems: [],
                      totalInputTokens: 0, inputTokensEstimated: true)
        let raw = #"{"role":"user","content":"Hello, world! The weather is nice."}"#
        let event = TraceEvent(runID: run.id, kind: .requestStart, payload: Data(raw.utf8))
        let exported = try TraceExporter().export(run: run, events: [event])
        let (_, events) = try TraceExporter().import(from: exported)
        let text = String(data: events.first?.payload ?? Data(), encoding: .utf8) ?? ""
        XCTAssertTrue(text.contains("Hello, world!"))
        XCTAssertFalse(text.contains("[REDACTED]"))
    }
}
