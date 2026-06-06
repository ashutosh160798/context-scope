// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ContextScopeDemoData",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ContextScopeDemoData", targets: ["ContextScopeDemoData"]),
    ],
    dependencies: [
        .package(path: "../ContextScopeCore"),
    ],
    targets: [
        .target(
            name: "ContextScopeDemoData",
            dependencies: ["ContextScopeCore"],
            path: "Sources/ContextScopeDemoData",
            resources: [.copy("Fixtures")]
        ),
        .testTarget(
            name: "ContextScopeDemoDataTests",
            dependencies: ["ContextScopeDemoData"],
            path: "Tests/ContextScopeDemoDataTests"
        ),
    ]
)
