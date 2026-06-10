import Foundation
import ContextScopeCore

public struct TraceExporter: Sendable {
    public init() {}

    /// Export a run and its events to `.contextscope.json` format.
    /// Secret patterns (Bearer tokens, `sk-…` keys, `api_key` values) are
    /// redacted from event payloads before the file is written.
    public func export(run: Run, events: [TraceEvent]) throws -> Data {
        let sanitizedEvents = events.map { event -> TraceEvent in
            guard let text = String(data: event.payload, encoding: .utf8), !text.isEmpty else {
                return event
            }
            let clean = redact(text)
            guard clean != text, let cleanData = clean.data(using: .utf8) else { return event }
            return TraceEvent(id: event.id, runID: event.runID, kind: event.kind,
                              timestamp: event.timestamp, payload: cleanData)
        }
        let payload = ExportPayload(version: "0.1", run: run, events: sanitizedEvents)
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

    // MARK: - Private redaction

    // Mirrors Sanitizer.sanitize(content:) without adding a cross-package dependency.
    private func redact(_ text: String) -> String {
        var result = text
        let rules: [(String, String)] = [
            (#"Bearer\s+[A-Za-z0-9._-]{20,}"#, "Bearer [REDACTED]"),
            (#"sk-[A-Za-z0-9-]{10,}"#, "[REDACTED]"),
            (#"(?i)(\"?api[_-]?key\"?\s*[:=]\s*\"?)[A-Za-z0-9._-]{16,}"#, "$1[REDACTED]"),
        ]
        for (pattern, replacement) in rules {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            result = regex.stringByReplacingMatches(
                in: result, range: NSRange(result.startIndex..., in: result),
                withTemplate: replacement)
        }
        return result
    }
}

private struct ExportPayload: Codable {
    let version: String
    let run: Run
    let events: [TraceEvent]
}
