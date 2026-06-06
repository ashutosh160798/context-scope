import Foundation
import ContextScopeCore

@MainActor
public final class ReplayEngine: ObservableObject {
    @Published public private(set) var currentSnapshot: ContextSnapshot?
    @Published public private(set) var currentFrameIndex: Int = 0
    @Published public private(set) var isPlaying: Bool = false

    private let frames: [ContextSnapshot]
    private var playTask: Task<Void, Never>?

    public var frameCount: Int { frames.count }
    public var progress: Double {
        guard frames.count > 1 else { return 0 }
        return Double(currentFrameIndex) / Double(frames.count - 1)
    }

    public init(frames: [ContextSnapshot]) {
        self.frames = frames
        self.currentSnapshot = frames.first
    }

    public func seek(to index: Int) {
        let clamped = max(0, min(index, frames.count - 1))
        currentFrameIndex = clamped
        currentSnapshot = frames[clamped]
    }

    public func stepForward() {
        seek(to: currentFrameIndex + 1)
    }

    public func stepBackward() {
        seek(to: currentFrameIndex - 1)
    }

    public func play(speed: Double = 1.0) async {
        guard !isPlaying else { return }
        isPlaying = true
        defer { isPlaying = false }

        while currentFrameIndex < frames.count - 1 {
            try? await Task.sleep(for: .seconds(1.0 / speed))
            if Task.isCancelled { break }
            seek(to: currentFrameIndex + 1)
        }
        isPlaying = false
    }

    public func pause() {
        playTask?.cancel()
        playTask = nil
        isPlaying = false
    }

    public func restart() {
        pause()
        seek(to: 0)
    }
}
