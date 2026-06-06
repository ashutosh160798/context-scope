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
        .testTarget(
            name: "ContextScopeVisualizationTests",
            dependencies: ["ContextScopeVisualization"],
            path: "Tests/ContextScopeVisualizationTests"
        ),
    ]
)
