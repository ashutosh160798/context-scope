import Foundation
import ContextScopeCore

public actor RunRepository {
    private let database: Database

    public init(database: Database) {
        self.database = database
    }

    public func save(_ run: Run) async throws {
        fatalError("unimplemented")
    }

    public func fetch(for sessionID: UUID) async throws -> [Run] {
        fatalError("unimplemented")
    }

    public func delete(id: UUID) async throws {
        fatalError("unimplemented")
    }
}
