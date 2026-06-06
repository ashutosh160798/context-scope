import Foundation
import ContextScopeCore

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
        guard let url = Bundle.module.url(
            forResource: scenario.fixtureFilename,
            withExtension: nil,
            subdirectory: "Fixtures"
        ) else {
            throw DemoLoadError.fixtureNotFound(scenario.fixtureFilename)
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let fixture = try decoder.decode(TraceFixture.self, from: data)
        let runID = UUID()
        let contextLimit = fixture.contextLimit ?? 128_000

        let frames: [ContextSnapshot] = fixture.frames.map { f in
            let items: [ContextItem] = f.items.map { raw in
                ContextItem(
                    category: ContextCategory(rawValue: raw.category) ?? .other,
                    tokenCount: raw.tokenCount,
                    estimatedTokenCount: raw.estimatedTokenCount,
                    content: raw.content
                )
            }
            return ContextSnapshot(
                runID: runID,
                timestamp: f.timestamp,
                items: items,
                totalTokens: f.totalTokens,
                contextLimit: contextLimit
            )
        }

        return DemoSession(
            scenario: scenario,
            model: fixture.model ?? "gpt-4o",
            contextLimit: contextLimit,
            frames: frames
        )
    }
}

public enum DemoLoadError: Error, LocalizedError {
    case fixtureNotFound(String)
    case decodingFailed(String)

    public var errorDescription: String? {
        switch self {
        case .fixtureNotFound(let name): return "Demo fixture '\(name)' not found in bundle."
        case .decodingFailed(let detail): return "Demo fixture decoding failed: \(detail)"
        }
    }
}

// MARK: - Fixture Decodable types

private struct TraceFixture: Decodable {
    let version: String
    let scenario: String
    let model: String?
    let contextLimit: Int?
    let frames: [FrameFixture]
}

private struct FrameFixture: Decodable {
    let timestamp: Date
    let totalTokens: Int
    let items: [ItemFixture]
}

private struct ItemFixture: Decodable {
    let category: String
    let tokenCount: Int
    let estimatedTokenCount: Bool
    let content: String
}
