import Foundation
import ContextScopeCore

public struct TraceExporter: Sendable {
    public init() {}

    public func export(run: Run, events: [TraceEvent]) throws -> Data {
        fatalError("unimplemented")
    }

    public func `import`(from data: Data) throws -> (Run, [TraceEvent]) {
        fatalError("unimplemented")
    }
}
