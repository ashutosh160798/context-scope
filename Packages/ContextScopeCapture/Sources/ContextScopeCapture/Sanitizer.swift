import Foundation

// Redacts secrets from headers before any logging, storage, or export.
public struct Sanitizer: Sendable {
    static let secretHeaderNames: Set<String> = [
        "authorization",
        "x-api-key",
        "api-key",
        "cookie",
        "set-cookie",
    ]

    public init() {}

    public func sanitize(headers: [String: String]) -> [String: String] {
        var result = headers
        for key in headers.keys {
            if Self.secretHeaderNames.contains(key.lowercased()) {
                result[key] = "[REDACTED]"
            }
        }
        return result
    }
}
