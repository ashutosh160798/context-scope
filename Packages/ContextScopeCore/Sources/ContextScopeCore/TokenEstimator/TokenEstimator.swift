import os.log

public actor TokenEstimator: TokenCounting {
    private let registry: ModelRegistry
    private let logger = Logger(subsystem: "com.contextscope.core", category: "TokenEstimator")

    public init(registry: ModelRegistry = ModelRegistry()) {
        self.registry = registry
    }

    // Conservative heuristic (~4 chars per token). Labeled as estimated in the UI.
    public nonisolated func countTokens(in text: String, model: String) -> Int {
        max(1, text.unicodeScalars.count / 4)
    }

    public nonisolated func isExact(for model: String) -> Bool { false }
}
