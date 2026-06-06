import Foundation

public struct Run: Identifiable, Codable, Sendable {
    public let id: UUID
    public let sessionID: UUID
    public let model: String
    public let requestedAt: Date
    public var completedAt: Date?
    public let contextItems: [ContextItem]
    public var totalInputTokens: Int
    public var totalOutputTokens: Int
    public let inputTokensEstimated: Bool

    public init(
        id: UUID = UUID(),
        sessionID: UUID,
        model: String,
        requestedAt: Date = Date(),
        contextItems: [ContextItem],
        totalInputTokens: Int,
        totalOutputTokens: Int = 0,
        inputTokensEstimated: Bool
    ) {
        self.id = id
        self.sessionID = sessionID
        self.model = model
        self.requestedAt = requestedAt
        self.contextItems = contextItems
        self.totalInputTokens = totalInputTokens
        self.totalOutputTokens = totalOutputTokens
        self.inputTokensEstimated = inputTokensEstimated
    }
}
