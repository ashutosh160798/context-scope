// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ContextScope",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "ContextScopeApp", targets: ["ContextScopeApp"]),
    ],
    dependencies: [
        .package(path: "Packages/ContextScopeCore"),
        .package(path: "Packages/ContextScopeCapture"),
        .package(path: "Packages/ContextScopeStorage"),
        .package(path: "Packages/ContextScopeVisualization"),
        .package(path: "Packages/ContextScopeDemoData"),
    ],
    targets: [
        .executableTarget(
            name: "ContextScopeApp",
            dependencies: [
                .product(name: "ContextScopeCore", package: "ContextScopeCore"),
                .product(name: "ContextScopeCapture", package: "ContextScopeCapture"),
                .product(name: "ContextScopeStorage", package: "ContextScopeStorage"),
                .product(name: "ContextScopeVisualization", package: "ContextScopeVisualization"),
                .product(name: "ContextScopeDemoData", package: "ContextScopeDemoData"),
            ],
            path: "App/ContextScopeApp/Sources"
        ),
    ]
)
