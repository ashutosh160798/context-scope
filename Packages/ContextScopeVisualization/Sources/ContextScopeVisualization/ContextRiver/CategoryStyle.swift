import SwiftUI
import ContextScopeCore

public struct CategoryStyle {
    public let color: Color
    public let label: String

    public static let styles: [ContextCategory: CategoryStyle] = [
        .systemPrompt: CategoryStyle(color: .blue, label: "System Prompt"),
        .conversationHistory: CategoryStyle(color: .green, label: "History"),
        .toolDefinitions: CategoryStyle(color: .orange, label: "Tool Definitions"),
        .retrievedContext: CategoryStyle(color: .purple, label: "Retrieved Context"),
        .toolOutputs: CategoryStyle(color: .yellow, label: "Tool Outputs"),
        .other: CategoryStyle(color: .gray, label: "Other"),
    ]

    public init(color: Color, label: String) {
        self.color = color
        self.label = label
    }
}
