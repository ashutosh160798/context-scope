import Foundation

public protocol StorageProvider: Sendable {
    func save(run: Run) async throws
    func fetchRuns(for sessionID: UUID) async throws -> [Run]
    func save(session: Session) async throws
    func fetchSessions(for projectID: UUID) async throws -> [Session]
    func deleteAll() async throws
}
