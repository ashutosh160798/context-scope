import Foundation

// Redacts secrets from headers before any logging, storage, or export.
public struct Sanitizer: Sendable {
    public static let secretHeaderNames: Set<String> = [
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

    /// Redact common API-key patterns from free-form text before export.
    /// Covers Bearer tokens, OpenAI-style keys (sk-…), and explicit
    /// `api_key: …` / `"api_key": "…"` patterns in JSON.
    public func sanitize(content: String) -> String {
        var result = content
        let patterns: [(String, String)] = [
            (#"Bearer\s+[A-Za-z0-9._-]{20,}"#, "Bearer [REDACTED]"),
            (#"sk-[A-Za-z0-9-]{10,}"#, "[REDACTED]"),
            (#"(?i)(\"?api[_-]?key\"?\s*[:=]\s*\"?)[A-Za-z0-9._-]{16,}"#, "$1[REDACTED]"),
        ]
        for (pattern, replacement) in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, range: range, withTemplate: replacement)
        }
        return result
    }
}
