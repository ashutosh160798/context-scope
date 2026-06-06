import Foundation
import ContextScopeCore

public struct RiverLane: Identifiable, Sendable {
    public let id: ContextCategory
    public let proportion: Double  // fraction of the model's context limit consumed
    public let tokenCount: Int

    public init(id: ContextCategory, proportion: Double, tokenCount: Int) {
        self.id = id
        self.proportion = proportion
        self.tokenCount = tokenCount
    }
}

public struct RiverLayout: Sendable {
    /// Aggregate items by category and return lanes ordered for display.
    /// Proportion is relative to `contextLimit`; if no limit, relative to totalTokens.
    public static func lanes(from snapshot: ContextSnapshot) -> [RiverLane] {
        var totals: [ContextCategory: Int] = [:]
        for item in snapshot.items {
            totals[item.category, default: 0] += item.tokenCount
        }

        let denominator = Double(snapshot.contextLimit ?? snapshot.totalTokens)
        guard denominator > 0 else { return [] }

        let displayOrder: [ContextCategory] = [
            .systemPrompt, .toolDefinitions, .conversationHistory,
            .retrievedContext, .toolOutputs, .other
        ]

        return displayOrder.compactMap { category in
            guard let count = totals[category], count > 0 else { return nil }
            return RiverLane(id: category, proportion: Double(count) / denominator, tokenCount: count)
        }
    }
}
