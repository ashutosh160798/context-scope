import Foundation
import os.log

public actor Database {
    public let url: URL
    private let logger = Logger(subsystem: "com.contextscope.storage", category: "Database")

    public init(url: URL) {
        self.url = url
    }

    public func open() async throws {
        fatalError("unimplemented")
    }

    public func migrate() async throws {
        fatalError("unimplemented")
    }
}
