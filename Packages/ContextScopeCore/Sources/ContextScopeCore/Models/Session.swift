import Foundation

public struct Session: Identifiable, Codable, Sendable {
    public let id: UUID
    public let projectID: UUID
    public let startedAt: Date
    public var endedAt: Date?

    public init(id: UUID = UUID(), projectID: UUID, startedAt: Date = Date()) {
        self.id = id
        self.projectID = projectID
        self.startedAt = startedAt
    }
}
