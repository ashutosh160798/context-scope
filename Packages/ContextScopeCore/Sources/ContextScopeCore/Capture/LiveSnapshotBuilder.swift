import Foundation

/// Folds streamed `TraceEvent`s into a growing `ContextSnapshot` for one run.
/// Pure value type with no UI or actor dependencies so it is unit-testable.
public struct LiveSnapshotBuilder: Sendable {
    public let runID: UUID
    public let contextLimit: Int?

    private var items: [ContextItem]
    private var streamedTokens: Int

    public init(runID: UUID, contextLimit: Int?) {
        self.runID = runID
        self.contextLimit = contextLimit
        self.items = []
        self.streamedTokens = 0
    }

    /// Replace the request-side items (system prompt, history, tools, etc.).
    public mutating func seed(items: [ContextItem]) {
        self.items = items
    }

    /// Apply one streamed event. Events for other runs are ignored.
    public mutating func apply(event: TraceEvent) {
        guard event.runID == runID else { return }
        switch event.kind {
        case .streamChunk, .toolResult, .toolCall:
            let text = String(data: event.payload, encoding: .utf8) ?? ""
            streamedTokens += max(0, text.unicodeScalars.count / 4)
        case .requestStart, .requestComplete, .error:
            break
        }
    }

    /// Materialize the current snapshot. Streamed tokens are exposed as a
    /// single `.toolOutputs` item so they render in their own river lane.
    public func snapshot() -> ContextSnapshot {
        var allItems = items
        if streamedTokens > 0 {
            allItems.append(ContextItem(
                category: .toolOutputs,
                tokenCount: streamedTokens,
                estimatedTokenCount: true,
                content: "(streamed output)"
            ))
        }
        let total = allItems.reduce(0) { $0 + $1.tokenCount }
        return ContextSnapshot(
            runID: runID,
            items: allItems,
            totalTokens: total,
            contextLimit: contextLimit
        )
    }
}
