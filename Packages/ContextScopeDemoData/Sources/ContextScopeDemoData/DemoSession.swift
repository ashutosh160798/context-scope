import Foundation
import ContextScopeCore

public struct DemoScenario: Identifiable, Sendable {
    public let id: String
    public let displayName: String
    public let description: String
    public let fixtureFilename: String

    public init(id: String, displayName: String, description: String, fixtureFilename: String) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.fixtureFilename = fixtureFilename
    }
}

public struct DemoSession: Sendable {
    public let scenario: DemoScenario
    public let frames: [ContextSnapshot]

    public init(scenario: DemoScenario, frames: [ContextSnapshot]) {
        self.scenario = scenario
        self.frames = frames
    }
}
