import Foundation

public enum ContextCategory: String, Codable, CaseIterable, Sendable {
    case systemPrompt = "system_prompt"
    case conversationHistory = "conversation_history"
    case toolDefinitions = "tool_definitions"
    case retrievedContext = "retrieved_context"
    case toolOutputs = "tool_outputs"
    case other = "other"
}

public struct ContextItem: Identifiable, Codable, Sendable {
    public let id: UUID
    public let category: ContextCategory
    public let tokenCount: Int
    public let estimatedTokenCount: Bool
    public let content: String

    public init(
        id: UUID = UUID(),
        category: ContextCategory,
        tokenCount: Int,
        estimatedTokenCount: Bool,
        content: String
    ) {
        self.id = id
        self.category = category
        self.tokenCount = tokenCount
        self.estimatedTokenCount = estimatedTokenCount
        self.content = content
    }
}
