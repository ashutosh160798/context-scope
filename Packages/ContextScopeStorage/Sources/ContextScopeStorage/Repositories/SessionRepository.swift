import Foundation
import ContextScopeCore

public actor SessionRepository: SessionStoring {
    private let database: Database
    private var cache: [UUID: [Session]] = [:]  // projectID → sessions

    public init(database: Database) {
        self.database = database
    }

    public func save(_ session: Session) async throws {
        var all = (try? await loadAll()) ?? [:]
        var sessions = all[session.projectID] ?? []
        sessions.removeAll { $0.id == session.id }
        sessions.append(session)
        all[session.projectID] = sessions
        try await writeAll(all)
        cache[session.projectID] = sessions
    }

    public func fetchSessions(for projectID: UUID) async throws -> [Session] {
        if let cached = cache[projectID] { return cached }
        let all = (try? await loadAll()) ?? [:]
        let sessions = all[projectID] ?? []
        cache[projectID] = sessions
        return sessions
    }

    public func deleteSession(id: UUID) async throws {
        var all = (try? await loadAll()) ?? [:]
        for (projectID, sessions) in all {
            let filtered = sessions.filter { $0.id != id }
            if filtered.count != sessions.count {
                all[projectID] = filtered
                cache[projectID] = filtered
            }
        }
        try await writeAll(all)
    }

    // MARK: Private

    private func loadAll() async throws -> [UUID: [Session]] {
        let path = await database.sessionsIndex()
        guard FileManager.default.fileExists(atPath: path.path) else { return [:] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try Data(contentsOf: path)
        let flat = try decoder.decode([Session].self, from: data)
        var result: [UUID: [Session]] = [:]
        for s in flat {
            result[s.projectID, default: []].append(s)
        }
        return result
    }

    private func writeAll(_ dict: [UUID: [Session]]) async throws {
        let path = await database.sessionsIndex()
        let flat = dict.values.flatMap { $0 }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(flat).write(to: path, options: .atomic)
    }
}
