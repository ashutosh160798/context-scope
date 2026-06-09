import Foundation

/// A single advisory surfaced when a context snapshot exhibits a known
/// anti-pattern (too full, dominated by one item, bloated tool definitions,
/// or duplicated blocks).
///
/// This is pure, UI-free value logic so it can be unit-tested in isolation and
/// reused by the menu bar, exports, or a future CLI — the SwiftUI layer only
/// maps `severity` to colors and icons.
public struct ContextWarning: Identifiable, Equatable, Sendable {
    public enum Severity: Int, Comparable, Sendable {
        case notice
        case warning
        case critical

        public static func < (lhs: Severity, rhs: Severity) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    public enum Kind: String, Sendable {
        case contextPressure
        case dominantItem
        case bloatedToolDefinitions
        case duplicateContent
    }

    public let kind: Kind
    public let severity: Severity
    public let message: String

    /// Stable identity for SwiftUI `ForEach` without relying on array indices.
    public var id: String { "\(kind.rawValue):\(message)" }

    public init(kind: Kind, severity: Severity, message: String) {
        self.kind = kind
        self.severity = severity
        self.message = message
    }
}

public extension ContextSnapshot {
    /// Tokens (in unit fraction) above which a single item is considered to
    /// dominate the input.
    private static let dominantItemThreshold = 0.25
    /// Aggregate tool-definition fraction above which tool definitions are
    /// considered to be bloating every request.
    private static let bloatedToolThreshold = 0.20

    /// Evaluate this snapshot against the v0.1 warning heuristics, sorted with
    /// the most severe warnings first. Returns an empty array for a healthy
    /// snapshot.
    var warnings: [ContextWarning] {
        var result: [ContextWarning] = []

        // 1. Context pressure relative to the model's limit.
        if let pct = pressurePercent {
            let shown = String(format: "%.0f", pct)
            if pct >= 95 {
                result.append(.init(
                    kind: .contextPressure,
                    severity: .critical,
                    message: "Context at \(shown)% of the model limit — the response may be truncated."
                ))
            } else if pct >= 85 {
                result.append(.init(
                    kind: .contextPressure,
                    severity: .warning,
                    message: "Context at \(shown)% of the model limit — approaching capacity."
                ))
            } else if pct >= 70 {
                result.append(.init(
                    kind: .contextPressure,
                    severity: .notice,
                    message: "Context at \(shown)% of the model limit."
                ))
            }
        }

        // 2. A single item dominating the input.
        if totalTokens > 0 {
            for item in items where Double(item.tokenCount) / Double(totalTokens) > Self.dominantItemThreshold {
                let pct = String(format: "%.0f", Double(item.tokenCount) / Double(totalTokens) * 100)
                result.append(.init(
                    kind: .dominantItem,
                    severity: .warning,
                    message: "A \(item.category.displayName) item uses \(pct)% of the input — consider trimming or summarizing it."
                ))
            }
        }

        // 3. Bloated tool definitions (aggregate across all tool-def items).
        if totalTokens > 0 {
            let toolDefTokens = items
                .filter { $0.category == .toolDefinitions }
                .reduce(0) { $0 + $1.tokenCount }
            let fraction = Double(toolDefTokens) / Double(totalTokens)
            if toolDefTokens > 0 && fraction > Self.bloatedToolThreshold {
                let pct = String(format: "%.0f", fraction * 100)
                result.append(.init(
                    kind: .bloatedToolDefinitions,
                    severity: .warning,
                    message: "Tool definitions use \(pct)% of the input — unused tools inflate every request."
                ))
            }
        }

        // 4. Duplicate content (same non-empty block appearing more than once).
        // Reported once per affected category to avoid flooding the banner.
        var seenContent: Set<String> = []
        var flaggedCategories: Set<ContextCategory> = []
        for item in items {
            let key = item.content.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !key.isEmpty else { continue }
            if !seenContent.insert(key).inserted, flaggedCategories.insert(item.category).inserted {
                result.append(.init(
                    kind: .duplicateContent,
                    severity: .notice,
                    message: "Duplicate \(item.category.displayName) detected — the same block appears more than once."
                ))
            }
        }

        return result.sorted { $0.severity > $1.severity }
    }
}
