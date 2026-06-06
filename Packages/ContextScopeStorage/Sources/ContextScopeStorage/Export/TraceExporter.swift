import Foundation
import ContextScopeCore

public struct TraceExporter: Sendable {
    public init() {}

    public func export(run: Run, events: [TraceEvent]) throws -> Data {
        let payload = ExportPayload(version: "0.1", run: run, events: events)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(payload)
    }

    public func `import`(from data: Data) throws -> (Run, [TraceEvent]) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let payload = try decoder.decode(ExportPayload.self, from: data)
        return (payload.run, payload.events)
    }
}

private struct ExportPayload: Codable {
    let version: String
    let run: Run
    let events: [TraceEvent]
}
