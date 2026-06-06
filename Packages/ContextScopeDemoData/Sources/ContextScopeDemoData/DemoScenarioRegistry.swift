import Foundation

public enum DemoScenarioRegistry {
    public static let all: [DemoScenario] = [
        DemoScenario(
            id: "healthy_request",
            displayName: "Healthy Request",
            description: "Moderate context, one tool call, low pressure.",
            fixtureFilename: "healthy_request.contextscope.json"
        ),
        DemoScenario(
            id: "bloated_context",
            displayName: "Bloated Context",
            description: "Oversized tool definitions, duplicate history, >85% context pressure.",
            fixtureFilename: "bloated_context.contextscope.json"
        ),
        DemoScenario(
            id: "runaway_tool_loop",
            displayName: "Runaway Tool Loop",
            description: "Repeated tool calls, growing results, increasing latency, final failure.",
            fixtureFilename: "runaway_tool_loop.contextscope.json"
        ),
    ]

    public static func load(scenario: DemoScenario) throws -> DemoSession {
        fatalError("unimplemented")
    }
}
