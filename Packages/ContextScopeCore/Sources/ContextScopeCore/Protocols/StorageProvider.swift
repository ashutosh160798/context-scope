import Foundation

// RunRepository conforms to RunStoring; SessionRepository conforms to SessionStoring.
// StorageProvider is the combined interface for app-layer dependency injection.
public protocol RunStoring: Sendable {
    func save(_ run: Run) async throws
    func fetchRuns(for sessionID: UUID) async throws -> [Run]
    func deleteRun(id: UUID) async throws
}

public protocol SessionStoring: Sendable {
    func save(_ session: Session) async throws
    func fetchSessions(for projectID: UUID) async throws -> [Session]
    func deleteSession(id: UUID) async throws
}

public typealias StorageProvider = RunStoring & SessionStoring
