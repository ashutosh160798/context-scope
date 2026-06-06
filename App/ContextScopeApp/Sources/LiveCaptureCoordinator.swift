import Foundation
import ContextScopeCore
import ContextScopeCapture

/// Bridges the proxy's `AsyncStream<TraceEvent>` to published UI state.
/// Runs on MainActor so its @Published properties are safe to bind to SwiftUI.
@MainActor
final class LiveCaptureCoordinator: ObservableObject {
    @Published private(set) var liveSnapshot: ContextSnapshot?
    @Published private(set) var liveTokenCount: Int = 0

    private var consumeTask: Task<Void, Never>?

    /// Start consuming events from the proxy. One builder per run; new `requestStart`
    /// events create a fresh builder so sequential requests don't accumulate into one snapshot.
    func start(events: AsyncStream<TraceEvent>) {
        consumeTask = Task { [weak self] in
            var builder: LiveSnapshotBuilder?

            for await event in events {
                guard let self else { break }
                switch event.kind {
                case .requestStart:
                    builder = LiveSnapshotBuilder(runID: event.runID, contextLimit: nil)
                case .requestComplete:
                    if var b = builder, b.runID == event.runID {
                        b.apply(event: event)
                        let snap = b.snapshot()
                        self.liveSnapshot = snap
                        self.liveTokenCount = snap.totalTokens
                    }
                    builder = nil
                default:
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

    func stop() {
        consumeTask?.cancel()
        consumeTask = nil
        liveSnapshot = nil
        liveTokenCount = 0
    }
}
