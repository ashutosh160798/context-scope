public protocol TokenCounting: Sendable {
    func countTokens(in text: String, model: String) -> Int
    func isExact(for model: String) -> Bool
}
