import Foundation
import os.log

/// JSON-file-backed persistence. Keeps runs/sessions as JSON files under Application Support.
/// Designed to be replaced with SQLite in a future release.
public actor Database {
    public let url: URL  // root directory for all storage files
    private let logger = Logger(subsystem: "com.contextscope.storage", category: "Database")

    public init(url: URL) {
        self.url = url
    }

    public func open() async throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: runsDirectory(), withIntermediateDirectories: true)
        logger.info("Database opened at \(self.url.path)")
    }

    public func migrate() async throws {
        // No schema migrations needed for JSON storage; method exists for future SQLite drop-in.
    }

    // MARK: Internal helpers used by repositories

    func readJSON<T: Decodable>(_ type: T.Type, from path: URL) throws -> T {
        let data = try Data(contentsOf: path)
        return try JSONDecoder().decode(type, from: data)
    }

    func writeJSON<T: Encodable>(_ value: T, to path: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(value)
        try data.write(to: path, options: .atomic)
    }

    func sessionsIndex() -> URL { url.appendingPathComponent("sessions.json") }
    func runsDirectory() -> URL { url.appendingPathComponent("runs") }
    func runFile(id: UUID) -> URL { url.appendingPathComponent("runs/\(id.uuidString).json") }
}
