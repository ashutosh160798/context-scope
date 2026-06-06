import Foundation
import ContextScopeCore

@MainActor
public final class ReplayEngine: ObservableObject {
    @Published public private(set) var currentSnapshot: ContextSnapshot?
    @Published public private(set) var currentFrameIndex: Int = 0

    private let frames: [ContextSnapshot]

    public init(frames: [ContextSnapshot]) {
        self.frames = frames
    }

    public func seek(to index: Int) {
        fatalError("unimplemented")
    }

    public func play() async {
        fatalError("unimplemented")
    }
}
