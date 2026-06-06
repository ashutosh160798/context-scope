import Foundation
import os.log
import ContextScopeCore

public actor ProxyServer {
    public let port: UInt16
    private let logger = Logger(subsystem: "com.contextscope.capture", category: "ProxyServer")

    public init(port: UInt16 = 4319) {
        self.port = port
    }

    public func start() async throws {
        fatalError("unimplemented")
    }

    public func stop() async {
        fatalError("unimplemented")
    }
}
