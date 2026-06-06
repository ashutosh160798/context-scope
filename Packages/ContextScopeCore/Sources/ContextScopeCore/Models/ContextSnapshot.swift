import Foundation

public struct ContextSnapshot: Codable, Sendable {
    public let runID: UUID
    public let timestamp: Date
    public let items: [ContextItem]
    public let totalTokens: Int
    public let contextLimit: Int?

    public var pressurePercent: Double? {
        guard let limit = contextLimit, limit > 0 else { return nil }
        return Double(totalTokens) / Double(limit) * 100
    }

    public init(
        runID: UUID,
        timestamp: Date = Date(),
        items: [ContextItem],
        totalTokens: Int,
        contextLimit: Int? = nil
    ) {
        self.runID = runID
        self.timestamp = timestamp
        self.items = items
        self.totalTokens = totalTokens
        self.contextLimit = contextLimit
    }
}
