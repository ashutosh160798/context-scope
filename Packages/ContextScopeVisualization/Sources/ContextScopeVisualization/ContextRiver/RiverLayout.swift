import Foundation
import ContextScopeCore

public struct RiverLane: Identifiable, Sendable {
    public let id: ContextCategory
    public let proportion: Double

    public init(id: ContextCategory, proportion: Double) {
        self.id = id
        self.proportion = proportion
    }
}

public struct RiverLayout: Sendable {
    public static func lanes(from snapshot: ContextSnapshot) -> [RiverLane] {
        fatalError("unimplemented")
    }
}
