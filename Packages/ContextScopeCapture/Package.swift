// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ContextScopeCapture",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ContextScopeCapture", targets: ["ContextScopeCapture"]),
    ],
    dependencies: [
        .package(path: "../ContextScopeCore"),
    ],
    targets: [
        .target(
            name: "ContextScopeCapture",
            dependencies: ["ContextScopeCore"],
            path: "Sources/ContextScopeCapture"
        ),
        .testTarget(
            name: "ContextScopeCaptureTests",
            dependencies: ["ContextScopeCapture"],
            path: "Tests/ContextScopeCaptureTests"
        ),
    ]
)
