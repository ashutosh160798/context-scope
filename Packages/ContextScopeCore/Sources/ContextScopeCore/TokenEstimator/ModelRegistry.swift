public struct ModelEntry: Sendable {
    public let id: String
    public let contextLimit: Int
    public let inputPricePer1KTokens: Double
    public let outputPricePer1KTokens: Double

    public init(id: String, contextLimit: Int, inputPricePer1KTokens: Double, outputPricePer1KTokens: Double) {
        self.id = id
        self.contextLimit = contextLimit
        self.inputPricePer1KTokens = inputPricePer1KTokens
        self.outputPricePer1KTokens = outputPricePer1KTokens
    }
}

public struct ModelRegistry: Sendable {
    private let models: [String: ModelEntry]

    public init() {
        // Pricing is approximate and versioned; labeled as estimated in the UI
        self.models = [
            "gpt-4o": ModelEntry(id: "gpt-4o", contextLimit: 128_000, inputPricePer1KTokens: 0.0025, outputPricePer1KTokens: 0.010),
            "gpt-4o-mini": ModelEntry(id: "gpt-4o-mini", contextLimit: 128_000, inputPricePer1KTokens: 0.00015, outputPricePer1KTokens: 0.0006),
        ]
    }

    public func entry(for modelID: String) -> ModelEntry? {
        models[modelID] ?? models.first(where: { modelID.hasPrefix($0.key) })?.value
    }
}
