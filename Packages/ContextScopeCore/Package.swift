// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ContextScopeCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ContextScopeCore", targets: ["ContextScopeCore"]),
    ],
    targets: [
        .target(
            name: "ContextScopeCore",
            path: "Sources/ContextScopeCore"
        ),
        .testTarget(
            name: "ContextScopeCoreTests",
            dependencies: ["ContextScopeCore"],
            path: "Tests/ContextScopeCoreTests"
        ),
    ]
)
