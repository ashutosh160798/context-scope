import Foundation
import ContextScopeCore

public actor RunRepository: RunStoring {
    private let database: Database

    public init(database: Database) {
        self.database = database
    }

    public func save(_ run: Run) async throws {
        let path = await database.runFile(id: run.id)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(run).write(to: path, options: .atomic)
    }

    public func fetchRuns(for sessionID: UUID) async throws -> [Run] {
        let dir = await database.runsDirectory()
        let files = (try? FileManager.default.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: nil
        )) ?? []

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return files.compactMap { url -> Run? in
            guard url.pathExtension == "json",
                  let data = try? Data(contentsOf: url),
                  let run = try? decoder.decode(Run.self, from: data),
                  run.sessionID == sessionID
            else { return nil }
            return run
        }.sorted { $0.requestedAt < $1.requestedAt }
    }

    public func deleteRun(id: UUID) async throws {
        let path = await database.runFile(id: id)
        try FileManager.default.removeItem(at: path)
    }
}
