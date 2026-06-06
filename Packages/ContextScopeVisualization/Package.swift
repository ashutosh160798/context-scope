// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ContextScopeVisualization",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ContextScopeVisualization", targets: ["ContextScopeVisualization"]),
    ],
    dependencies: [
        .package(path: "../ContextScopeCore"),
    ],
    targets: [
        .target(
            name: "ContextScopeVisualization",
            dependencies: ["ContextScopeCore"],
            path: "Sources/ContextScopeVisualization"
        ),
        // No test target: SwiftUI views require a running display and are tested manually
    ]
)
