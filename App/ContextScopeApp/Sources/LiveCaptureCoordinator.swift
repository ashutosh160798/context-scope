import Foundation
import ContextScopeCore
import ContextScopeCapture

/// Bridges the proxy's `AsyncStream<TraceEvent>` to published UI state.
/// Runs on MainActor so its @Published properties are safe to bind to SwiftUI.
@MainActor
final class LiveCaptureCoordinator: ObservableObject {
    @Published private(set) var liveSnapshot: ContextSnapshot?
    @Published private(set) var liveTokenCount: Int = 0

    /// Called when a run finishes (requestComplete received).
    /// Parameters: final snapshot, model name, input-only context items.
    var onRunComplete: ((ContextSnapshot, String, [ContextItem]) -> Void)?

    private var consumeTask: Task<Void, Never>?
    private let adapter = OpenAIAdapter()
    private let registry = ModelRegistry()

    func start(events: AsyncStream<TraceEvent>) {
        consumeTask = Task { [weak self] in
            var builder: LiveSnapshotBuilder?
            var currentModel = "unknown"
            var inputItems: [ContextItem] = []

            for await event in events {
                guard let self else { break }
                switch event.kind {
                case .requestStart:
                    let parsed = self.parseRequest(from: event.payload)
                    currentModel = parsed.model
                    inputItems = parsed.items
                    var b = LiveSnapshotBuilder(runID: event.runID, contextLimit: parsed.limit)
                    b.seed(items: parsed.items)
                    builder = b
                    let snap = b.snapshot()
                    self.liveSnapshot = snap
                    self.liveTokenCount = snap.totalTokens

                case .requestComplete:
                    if var b = builder, b.runID == event.runID {
                        b.apply(event: event)
                        let snap = b.snapshot()
                        self.liveSnapshot = snap
                        self.liveTokenCount = snap.totalTokens
                        self.onRunComplete?(snap, currentModel, inputItems)
                    }
                    builder = nil
                    currentModel = "unknown"
                    inputItems = []

                default:
                    if builder?.runID == event.runID {
                        builder?.apply(event: event)
                        if let b = builder {
                            let snap = b.snapshot()
                            self.liveSnapshot = snap
                            self.liveTokenCount = snap.totalTokens
                        }
                    }
                }
            }
        }
    }

    func stop() {
        consumeTask?.cancel()
        consumeTask = nil
        liveSnapshot = nil
        liveTokenCount = 0
    }

    // MARK: - Private

    private struct ParsedRequestInfo {
        let model: String
        let items: [ContextItem]
        let limit: Int?
    }

    private func parseRequest(from body: Data) -> ParsedRequestInfo {
        guard !body.isEmpty else { return ParsedRequestInfo(model: "unknown", items: [], limit: nil) }
        let req = HTTPRequest(method: "POST", path: "/v1/chat/completions", headers: [:], body: body)
        guard let parsed = try? adapter.parseRequest(req) else {
            return ParsedRequestInfo(model: "unknown", items: [], limit: nil)
        }
        let limit = registry.entry(for: parsed.model)?.contextLimit
        return ParsedRequestInfo(model: parsed.model, items: parsed.contextItems, limit: limit)
    }
}
