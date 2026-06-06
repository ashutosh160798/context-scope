import Foundation

public struct ContextSnapshot: Codable, Sendable {
    // runID is absent from trace file JSON (synthesized on decode); present when constructed in-memory
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        runID = try container.decodeIfPresent(UUID.self, forKey: .runID) ?? UUID()
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        items = try container.decode([ContextItem].self, forKey: .items)
        totalTokens = try container.decode(Int.self, forKey: .totalTokens)
        contextLimit = try container.decodeIfPresent(Int.self, forKey: .contextLimit)
    }
}
