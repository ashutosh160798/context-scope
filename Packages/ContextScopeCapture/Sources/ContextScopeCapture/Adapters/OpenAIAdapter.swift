import Foundation
import ContextScopeCore

public struct OpenAIAdapter: ProviderAdapter {
    private let classifier: ContextClassifier
    private let estimator: TokenEstimator

    public init(classifier: ContextClassifier = ContextClassifier(), estimator: TokenEstimator = TokenEstimator()) {
        self.classifier = classifier
        self.estimator = estimator
    }

    public func canHandle(request: HTTPRequest) -> Bool {
        request.path.hasPrefix("/v1/chat/completions") || request.path.hasPrefix("/v1/responses")
    }

    public func parseRequest(_ request: HTTPRequest) throws -> ParsedRequest {
        guard let body = request.body else {
            throw AdapterError.missingBody
        }
        let json = try JSONSerialization.jsonObject(with: body) as? [String: Any] ?? [:]
        let model = json["model"] as? String ?? "unknown"
        let messages = json["messages"] as? [[String: Any]] ?? []
        let tools = json["tools"] as? [[String: Any]] ?? []

        var items: [ContextItem] = []

        // Parse each message
        for (index, message) in messages.enumerated() {
            let role = message["role"] as? String ?? "user"
            let category = classifier.classify(role: role, index: index)
            let content = extractContent(from: message)
            let tokenCount = estimator.countTokens(in: content, model: model)

            items.append(ContextItem(
                category: category,
                tokenCount: tokenCount,
                estimatedTokenCount: !estimator.isExact(for: model),
                content: content
            ))
        }

        // Parse tool definitions
        for tool in tools {
            let raw = (try? JSONSerialization.data(withJSONObject: tool)).flatMap { String(data: $0, encoding: .utf8) } ?? ""
            let tokenCount = estimator.countTokens(in: raw, model: model)
            items.append(ContextItem(
                category: .toolDefinitions,
                tokenCount: tokenCount,
                estimatedTokenCount: !estimator.isExact(for: model),
                content: raw
            ))
        }

        return ParsedRequest(model: model, contextItems: items, raw: request)
    }

    public func parseResponse(_ response: HTTPResponse, for request: ParsedRequest) throws -> ParsedResponse {
        guard let body = response.body else {
            return ParsedResponse(inputTokens: nil, outputTokens: nil, raw: response)
        }
        guard let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
              let usage = json["usage"] as? [String: Any] else {
            return ParsedResponse(inputTokens: nil, outputTokens: nil, raw: response)
        }
        let input = usage["prompt_tokens"] as? Int
        let output = usage["completion_tokens"] as? Int
        return ParsedResponse(inputTokens: input, outputTokens: output, raw: response)
    }

    public func parseStreamingEvent(_ line: String, context: StreamingContext) throws -> TraceEvent? {
        guard line.hasPrefix("data: ") else { return nil }
        let payload = String(line.dropFirst(6))
        guard payload != "[DONE]", !payload.isEmpty else { return nil }

        guard let data = payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        // Check for tool calls in streaming delta
        if let choices = json["choices"] as? [[String: Any]],
           let first = choices.first,
           let delta = first["delta"] as? [String: Any],
           let toolCalls = delta["tool_calls"] as? [[String: Any]],
           !toolCalls.isEmpty {
            return TraceEvent(
                runID: context.runID,
                kind: .toolCall,
                payload: data
            )
        }

        return TraceEvent(
            runID: context.runID,
            kind: .streamChunk,
            payload: data
        )
    }

    private func extractContent(from message: [String: Any]) -> String {
        if let content = message["content"] as? String {
            return content
        }
        if let parts = message["content"] as? [[String: Any]] {
            return parts.compactMap { part -> String? in
                if part["type"] as? String == "text" { return part["text"] as? String }
                return nil
            }.joined(separator: "\n")
        }
        return ""
    }
}

public enum AdapterError: Error, LocalizedError {
    case missingBody
    case unsupportedFormat

    public var errorDescription: String? {
        switch self {
        case .missingBody: return "Request body is missing."
        case .unsupportedFormat: return "Request body format is not supported."
        }
    }
}
