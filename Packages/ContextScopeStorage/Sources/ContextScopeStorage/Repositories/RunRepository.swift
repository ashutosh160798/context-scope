import Foundation
import ContextScopeCore

public actor RunRepository: RunStoring {
    private let database: Database

    public init(database: Database) {
        self.database = database
    }

    public func save(_ run: Run) async throws {
        fatalError("unimplemented")
    }

    public func fetchRuns(for sessionID: UUID) async throws -> [Run] {
        fatalError("unimplemented")
    }

    public func deleteRun(id: UUID) async throws {
        fatalError("unimplemented")
    }
}
