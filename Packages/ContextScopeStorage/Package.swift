// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ContextScopeStorage",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ContextScopeStorage", targets: ["ContextScopeStorage"]),
    ],
    dependencies: [
        .package(path: "../ContextScopeCore"),
    ],
    targets: [
        .target(
            name: "ContextScopeStorage",
            dependencies: ["ContextScopeCore"],
            path: "Sources/ContextScopeStorage"
        ),
        .testTarget(
            name: "ContextScopeStorageTests",
            dependencies: ["ContextScopeStorage"],
            path: "Tests/ContextScopeStorageTests"
        ),
    ]
)
