import Foundation
import ContextScopeCore

public actor SessionRepository: SessionStoring {
    private let database: Database

    public init(database: Database) {
        self.database = database
    }

    public func save(_ session: Session) async throws {
        fatalError("unimplemented")
    }

    public func fetchSessions(for projectID: UUID) async throws -> [Session] {
        fatalError("unimplemented")
    }

    public func deleteSession(id: UUID) async throws {
        fatalError("unimplemented")
    }
}
