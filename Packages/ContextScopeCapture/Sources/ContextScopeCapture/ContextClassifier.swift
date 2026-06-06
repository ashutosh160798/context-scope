import Foundation
import ContextScopeCore

public struct ContextClassifier: Sendable {
    public init() {}

    public func classify(role: String, index: Int) -> ContextCategory {
        switch role.lowercased() {
        case "system":
            return .systemPrompt
        case "user":
            return .conversationHistory
        case "assistant":
            return .conversationHistory
        case "tool":
            return .toolOutputs
        case "function":
            return .toolOutputs
        default:
            return .other
        }
    }

    public func classify(contentType: String) -> ContextCategory {
        switch contentType.lowercased() {
        case "tool_definition", "tool":
            return .toolDefinitions
        case "retrieved", "context", "document":
            return .retrievedContext
        default:
            return .other
        }
    }
}
