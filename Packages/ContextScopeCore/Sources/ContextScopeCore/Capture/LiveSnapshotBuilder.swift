import Foundation

/// Folds streamed `TraceEvent`s into a growing `ContextSnapshot` for one run.
/// Pure value type with no UI or actor dependencies so it is unit-testable.
public struct LiveSnapshotBuilder: Sendable {
    public let runID: UUID
    public let contextLimit: Int?

    private var items: [ContextItem]
    private var streamedTokens: Int

    // Exact counts from the provider's `usage` field in the response body.
    // When present, these replace the heuristic estimates for total token math.
    private var exactInputTokens: Int?
    private var exactOutputTokens: Int?

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
        case .requestComplete:
            // Parse exact usage counts from non-streaming response body.
            if let json = try? JSONSerialization.jsonObject(with: event.payload) as? [String: Any],
               let usage = json["usage"] as? [String: Any] {
                exactInputTokens = usage["prompt_tokens"] as? Int
                exactOutputTokens = usage["completion_tokens"] as? Int
            }
        case .requestStart, .error:
            break
        }
    }

    /// Materialize the current snapshot.
    ///
    /// Output tokens are taken from provider usage data when available
    /// (`estimatedTokenCount: false`), falling back to the heuristic
    /// accumulation from streaming chunks.
    public func snapshot() -> ContextSnapshot {
        var allItems = items

        let outputTokens = exactOutputTokens ?? streamedTokens
        let outputIsEstimated = exactOutputTokens == nil
        if outputTokens > 0 {
            allItems.append(ContextItem(
                category: .toolOutputs,
                tokenCount: outputTokens,
                estimatedTokenCount: outputIsEstimated,
                content: "(response output)"
            ))
        }

        // Use exact input total when available so `pressurePercent` is accurate.
        let total: Int
        if let exactIn = exactInputTokens {
            total = exactIn + (exactOutputTokens ?? streamedTokens)
        } else {
            total = allItems.reduce(0) { $0 + $1.tokenCount }
        }

        return ContextSnapshot(
            runID: runID,
            items: allItems,
            totalTokens: total,
            contextLimit: contextLimit
        )
    }
}
