# ContextScope Phase 2 — Live Proxy, Keychain, Menu Bar Implementation Plan

> **Status: COMPLETE** — All 14 tasks implemented and verified 2026-06-07. All 6 test suites green. Binary ad-hoc signed with network entitlements. Pushed to `main`.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire ContextScope's running proxy into the live UI, secure the API key in the Keychain, add a menu bar extra, ship a code-signed entitlements story for the SPM executable, and backfill tests + CI for the new logic.

**Architecture:** `ProxyServer` already exposes `events: AsyncStream<TraceEvent>`. We add a `LiveCaptureCoordinator` (a `@MainActor` class) that consumes that stream in a `Task`, folds events into a growing `ContextSnapshot`, and publishes it on `AppState`. The Context River view binds to that live snapshot. The API key moves into a small `KeychainStore` value type backed by `SecItem*`. A SwiftUI `MenuBarExtra` scene mirrors `AppState` (proxy status, live token count, quick actions). Entitlements are applied by an ad-hoc `codesign` post-build step driven from `Scripts/`, since SPM executables have no Xcode entitlements phase. New unit tests cover the adapter, river layout, classifier, keychain, and proxy lifecycle; CI builds the root package and runs the whole suite.

**Tech Stack:** Swift 6.3 toolchain, swift-tools 5.9, macOS 14, SwiftUI, AppKit (`NSStatusItem` via `MenuBarExtra`), Network.framework, Security.framework (Keychain), XCTest, GitHub Actions (`macos-14`).

---

## File Structure

**New files:**
- `Packages/ContextScopeCore/Sources/ContextScopeCore/Capture/LiveSnapshotBuilder.swift` — pure, testable reducer that folds `TraceEvent`s + a parsed request into a `ContextSnapshot`. Lives in Core so both the app and tests can use it without importing SwiftUI.
- `App/ContextScopeApp/Sources/LiveCaptureCoordinator.swift` — `@MainActor` bridge that drains `ProxyServer.events` into `AppState`.
- `App/ContextScopeApp/Sources/KeychainStore.swift` — `SecItem*` wrapper for the API key.
- `App/ContextScopeApp/Sources/MenuBarView.swift` — the `MenuBarExtra` content view.
- `App/ContextScopeApp/Resources/ContextScopeApp.entitlements` — network client + server entitlements.
- `Scripts/sign.sh` — ad-hoc `codesign` of the built executable with the entitlements file.
- `Packages/ContextScopeCore/Tests/ContextScopeCoreTests/LiveSnapshotBuilderTests.swift`
- `Packages/ContextScopeCapture/Tests/ContextScopeCaptureTests/OpenAIAdapterTests.swift`
- `Packages/ContextScopeCapture/Tests/ContextScopeCaptureTests/ContextClassifierTests.swift`
- `Packages/ContextScopeCapture/Tests/ContextScopeCaptureTests/ProxyServerLifecycleTests.swift`
- `Packages/ContextScopeVisualization/Tests/ContextScopeVisualizationTests/RiverLayoutTests.swift`
- `App/ContextScopeApp/Tests/ContextScopeAppTests/KeychainStoreTests.swift`

**Modified files:**
- `Packages/ContextScopeVisualization/Package.swift` — add a test target.
- `App/ContextScopeApp/Sources/AppState.swift` — live snapshot publishing, keychain-backed key, coordinator wiring.
- `App/ContextScopeApp/Sources/OnboardingView.swift` — write the key to Keychain instead of UserDefaults.
- `App/ContextScopeApp/Sources/ContextScopeApp.swift` — add `MenuBarExtra` scene.
- `App/ContextScopeApp/Sources/ContextRiverView.swift` — prefer the live snapshot when the proxy is active.
- `Package.swift` — add the app test target.
- `Scripts/test.sh` — run the whole suite from the root package.
- `.github/workflows/ci.yml` — build root package, run tests, sign.

---

## Task 1: `LiveSnapshotBuilder` — pure event reducer (Core)

**Files:**
- Create: `Packages/ContextScopeCore/Sources/ContextScopeCore/Capture/LiveSnapshotBuilder.swift`
- Test: `Packages/ContextScopeCore/Tests/ContextScopeCoreTests/LiveSnapshotBuilderTests.swift`

This is a `@MainActor`-free, Sendable value type. It seeds from a `ParsedRequest`'s `contextItems` and appends streamed assistant/tool-output tokens as `streamChunk` / `toolResult` events arrive, recomputing `totalTokens`. We keep it in Core (no SwiftUI) so it is unit-testable in isolation.

- [x] **Step 1: Write the failing test**

Create `Packages/ContextScopeCore/Tests/ContextScopeCoreTests/LiveSnapshotBuilderTests.swift`:

```swift
import XCTest
@testable import ContextScopeCore

final class LiveSnapshotBuilderTests: XCTestCase {
    private let runID = UUID()

    func testSeedingProducesSnapshotFromRequestItems() {
        var builder = LiveSnapshotBuilder(runID: runID, contextLimit: 128_000)
        builder.seed(items: [
            ContextItem(category: .systemPrompt, tokenCount: 100, estimatedTokenCount: true, content: "sys"),
            ContextItem(category: .conversationHistory, tokenCount: 50, estimatedTokenCount: true, content: "hi"),
        ])
        let snapshot = builder.snapshot()
        XCTAssertEqual(snapshot.runID, runID)
        XCTAssertEqual(snapshot.totalTokens, 150)
        XCTAssertEqual(snapshot.contextLimit, 128_000)
        XCTAssertEqual(snapshot.items.count, 2)
    }

    func testStreamChunkAccumulatesIntoToolOutputsLane() {
        var builder = LiveSnapshotBuilder(runID: runID, contextLimit: nil)
        builder.seed(items: [
            ContextItem(category: .systemPrompt, tokenCount: 40, estimatedTokenCount: true, content: "sys"),
        ])
        // 8 characters -> 2 tokens at ~4 chars/token
        builder.apply(event: TraceEvent(runID: runID, kind: .streamChunk, payload: Data("abcdefgh".utf8)))
        let snapshot = builder.snapshot()
        XCTAssertEqual(snapshot.totalTokens, 42)
        XCTAssertEqual(snapshot.items.last?.category, .toolOutputs)
        XCTAssertEqual(snapshot.items.last?.tokenCount, 2)
    }

    func testEventsForOtherRunsAreIgnored() {
        var builder = LiveSnapshotBuilder(runID: runID, contextLimit: nil)
        builder.seed(items: [ContextItem(category: .systemPrompt, tokenCount: 10, estimatedTokenCount: true, content: "x")])
        builder.apply(event: TraceEvent(runID: UUID(), kind: .streamChunk, payload: Data("abcdefgh".utf8)))
        XCTAssertEqual(builder.snapshot().totalTokens, 10)
    }
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `swift test --package-path Packages/ContextScopeCore --filter LiveSnapshotBuilderTests`
Expected: FAIL — `cannot find 'LiveSnapshotBuilder' in scope`.

- [x] **Step 3: Write the implementation**

Create `Packages/ContextScopeCore/Sources/ContextScopeCore/Capture/LiveSnapshotBuilder.swift`:

```swift
import Foundation

/// Folds streamed `TraceEvent`s into a growing `ContextSnapshot` for one run.
/// Pure value type with no UI or actor dependencies so it is unit-testable.
public struct LiveSnapshotBuilder: Sendable {
    public let runID: UUID
    public let contextLimit: Int?

    private var items: [ContextItem]
    private var streamedTokens: Int

    public init(runID: UUID, contextLimit: Int?) {
        self.runID = runID
        self.contextLimit = contextLimit
        self.items = []
        self.streamedTokens = 0
    }

    /// Replace the request-side items (system prompt, history, tools, etc.).
    public mutating func seed(items: [ContextItem]) {
        self.items = items
    }

    /// Apply one streamed event. Events for other runs are ignored.
    public mutating func apply(event: TraceEvent) {
        guard event.runID == runID else { return }
        switch event.kind {
        case .streamChunk, .toolResult, .toolCall:
            let text = String(data: event.payload, encoding: .utf8) ?? ""
            streamedTokens += max(0, text.unicodeScalars.count / 4)
        case .requestStart, .requestComplete, .error:
            break
        }
    }

    /// Materialize the current snapshot. Streamed tokens are exposed as a
    /// single `.toolOutputs` item so they render in their own river lane.
    public func snapshot() -> ContextSnapshot {
        var allItems = items
        if streamedTokens > 0 {
            allItems.append(ContextItem(
                category: .toolOutputs,
                tokenCount: streamedTokens,
                estimatedTokenCount: true,
                content: "(streamed output)"
            ))
        }
        let total = allItems.reduce(0) { $0 + $1.tokenCount }
        return ContextSnapshot(
            runID: runID,
            items: allItems,
            totalTokens: total,
            contextLimit: contextLimit
        )
    }
}
```

- [x] **Step 4: Run test to verify it passes**

Run: `swift test --package-path Packages/ContextScopeCore --filter LiveSnapshotBuilderTests`
Expected: PASS (3 tests).

- [x] **Step 5: Commit**

```bash
git add Packages/ContextScopeCore/Sources/ContextScopeCore/Capture/LiveSnapshotBuilder.swift Packages/ContextScopeCore/Tests/ContextScopeCoreTests/LiveSnapshotBuilderTests.swift
git commit -m "feat(core): add LiveSnapshotBuilder event reducer with tests"
```

---

## Task 2: `OpenAIAdapter.parseRequest` tests

**Files:**
- Test: `Packages/ContextScopeCapture/Tests/ContextScopeCaptureTests/OpenAIAdapterTests.swift`

`OpenAIAdapter.parseRequest` already exists. This task only adds the missing tests. The estimator uses ~4 chars/token (`max(1, unicodeScalars.count / 4)`), so the expected token counts below are computed from that heuristic.

- [x] **Step 1: Write the failing test**

Create `Packages/ContextScopeCapture/Tests/ContextScopeCaptureTests/OpenAIAdapterTests.swift`:

```swift
import XCTest
import ContextScopeCore
@testable import ContextScopeCapture

final class OpenAIAdapterTests: XCTestCase {
    private func request(body: String) -> HTTPRequest {
        HTTPRequest(
            method: "POST",
            path: "/v1/chat/completions",
            headers: ["Content-Type": "application/json"],
            body: Data(body.utf8)
        )
    }

    func testParseRequestClassifiesRolesIntoCategories() throws {
        let adapter = OpenAIAdapter()
        let json = """
        {"model":"gpt-4o","messages":[
          {"role":"system","content":"You are helpful"},
          {"role":"user","content":"Hello there"},
          {"role":"assistant","content":"Hi!"}
        ]}
        """
        let parsed = try adapter.parseRequest(request(body: json))
        XCTAssertEqual(parsed.model, "gpt-4o")
        XCTAssertEqual(parsed.contextItems.count, 3)
        XCTAssertEqual(parsed.contextItems[0].category, .systemPrompt)
        XCTAssertEqual(parsed.contextItems[1].category, .conversationHistory)
        XCTAssertEqual(parsed.contextItems[2].category, .conversationHistory)
    }

    func testParseRequestAddsToolDefinitionItems() throws {
        let adapter = OpenAIAdapter()
        let json = """
        {"model":"gpt-4o","messages":[{"role":"user","content":"hi"}],
         "tools":[{"type":"function","function":{"name":"get_weather"}}]}
        """
        let parsed = try adapter.parseRequest(request(body: json))
        XCTAssertEqual(parsed.contextItems.filter { $0.category == .toolDefinitions }.count, 1)
    }

    func testParseRequestThrowsOnMissingBody() {
        let adapter = OpenAIAdapter()
        let req = HTTPRequest(method: "POST", path: "/v1/chat/completions", headers: [:], body: nil)
        XCTAssertThrowsError(try adapter.parseRequest(req)) { error in
            XCTAssertEqual(error as? AdapterError, .missingBody)
        }
    }

    func testParseRequestEstimatesTokensWithFourCharHeuristic() throws {
        let adapter = OpenAIAdapter()
        // content "12345678" = 8 scalars -> 2 tokens
        let json = #"{"model":"gpt-4o","messages":[{"role":"user","content":"12345678"}]}"#
        let parsed = try adapter.parseRequest(request(body: json))
        XCTAssertEqual(parsed.contextItems[0].tokenCount, 2)
        XCTAssertTrue(parsed.contextItems[0].estimatedTokenCount)
    }
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `swift test --package-path Packages/ContextScopeCapture --filter OpenAIAdapterTests`
Expected: FAIL at compile — `AdapterError` must be `Equatable` for `XCTAssertEqual`. (If it already conforms, the test runs; in this codebase it does not yet conform.)

- [x] **Step 3: Make `AdapterError` Equatable**

In `Packages/ContextScopeCapture/Sources/ContextScopeCapture/Adapters/OpenAIAdapter.swift`, change the enum declaration line:

```swift
public enum AdapterError: Error, LocalizedError {
```

to:

```swift
public enum AdapterError: Error, LocalizedError, Equatable {
```

- [x] **Step 4: Run test to verify it passes**

Run: `swift test --package-path Packages/ContextScopeCapture --filter OpenAIAdapterTests`
Expected: PASS (4 tests).

- [x] **Step 5: Commit**

```bash
git add Packages/ContextScopeCapture/Tests/ContextScopeCaptureTests/OpenAIAdapterTests.swift Packages/ContextScopeCapture/Sources/ContextScopeCapture/Adapters/OpenAIAdapter.swift
git commit -m "test(capture): cover OpenAIAdapter.parseRequest; make AdapterError Equatable"
```

---

## Task 3: `ContextClassifier.classify` tests

**Files:**
- Test: `Packages/ContextScopeCapture/Tests/ContextScopeCaptureTests/ContextClassifierTests.swift`

- [x] **Step 1: Write the failing test**

Create `Packages/ContextScopeCapture/Tests/ContextScopeCaptureTests/ContextClassifierTests.swift`:

```swift
import XCTest
import ContextScopeCore
@testable import ContextScopeCapture

final class ContextClassifierTests: XCTestCase {
    private let classifier = ContextClassifier()

    func testRoleMapping() {
        XCTAssertEqual(classifier.classify(role: "system", index: 0), .systemPrompt)
        XCTAssertEqual(classifier.classify(role: "user", index: 1), .conversationHistory)
        XCTAssertEqual(classifier.classify(role: "assistant", index: 2), .conversationHistory)
        XCTAssertEqual(classifier.classify(role: "tool", index: 3), .toolOutputs)
        XCTAssertEqual(classifier.classify(role: "function", index: 4), .toolOutputs)
    }

    func testRoleMappingIsCaseInsensitive() {
        XCTAssertEqual(classifier.classify(role: "SYSTEM", index: 0), .systemPrompt)
        XCTAssertEqual(classifier.classify(role: "User", index: 1), .conversationHistory)
    }

    func testUnknownRoleFallsBackToOther() {
        XCTAssertEqual(classifier.classify(role: "developer", index: 0), .other)
    }

    func testContentTypeMapping() {
        XCTAssertEqual(classifier.classify(contentType: "tool_definition"), .toolDefinitions)
        XCTAssertEqual(classifier.classify(contentType: "retrieved"), .retrievedContext)
        XCTAssertEqual(classifier.classify(contentType: "document"), .retrievedContext)
        XCTAssertEqual(classifier.classify(contentType: "mystery"), .other)
    }
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `swift test --package-path Packages/ContextScopeCapture --filter ContextClassifierTests`
Expected: FAIL — `no tests matched` / compile error referencing the new file (the type already exists, so this confirms the test file compiles and runs).

Note: `ContextClassifier` and `ContextCategory` already exist; this test should compile and pass immediately. If it passes on first run, that is expected — the value of this task is regression coverage. Proceed to Step 4.

- [x] **Step 3: No implementation change needed**

`ContextClassifier.classify(role:index:)` and `classify(contentType:)` already implement this behavior. No edit required.

- [x] **Step 4: Run test to verify it passes**

Run: `swift test --package-path Packages/ContextScopeCapture --filter ContextClassifierTests`
Expected: PASS (4 tests).

- [x] **Step 5: Commit**

```bash
git add Packages/ContextScopeCapture/Tests/ContextScopeCaptureTests/ContextClassifierTests.swift
git commit -m "test(capture): add ContextClassifier coverage"
```

---

## Task 4: `RiverLayout.lanes` tests (add test target to Visualization)

**Files:**
- Modify: `Packages/ContextScopeVisualization/Package.swift`
- Test: `Packages/ContextScopeVisualization/Tests/ContextScopeVisualizationTests/RiverLayoutTests.swift`

`RiverLayout` is pure logic (no SwiftUI), so it is safe to test even though the package currently declares no test target.

- [x] **Step 1: Add the test target to the package manifest**

In `Packages/ContextScopeVisualization/Package.swift`, replace these lines:

```swift
        .target(
            name: "ContextScopeVisualization",
            dependencies: ["ContextScopeCore"],
            path: "Sources/ContextScopeVisualization"
        ),
        // No test target: SwiftUI views require a running display and are tested manually
    ]
```

with:

```swift
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
```

- [x] **Step 2: Write the failing test**

Create `Packages/ContextScopeVisualization/Tests/ContextScopeVisualizationTests/RiverLayoutTests.swift`:

```swift
import XCTest
import ContextScopeCore
@testable import ContextScopeVisualization

final class RiverLayoutTests: XCTestCase {
    private func snapshot(items: [ContextItem], limit: Int?) -> ContextSnapshot {
        ContextSnapshot(
            runID: UUID(),
            items: items,
            totalTokens: items.reduce(0) { $0 + $1.tokenCount },
            contextLimit: limit
        )
    }

    func testLanesAggregateByCategory() {
        let snap = snapshot(items: [
            ContextItem(category: .systemPrompt, tokenCount: 100, estimatedTokenCount: true, content: "a"),
            ContextItem(category: .conversationHistory, tokenCount: 200, estimatedTokenCount: true, content: "b"),
            ContextItem(category: .conversationHistory, tokenCount: 100, estimatedTokenCount: true, content: "c"),
        ], limit: 1000)
        let lanes = RiverLayout.lanes(from: snap)
        XCTAssertEqual(lanes.count, 2)
        XCTAssertEqual(lanes.first { $0.id == .conversationHistory }?.tokenCount, 300)
    }

    func testProportionUsesContextLimitAsDenominator() {
        let snap = snapshot(items: [
            ContextItem(category: .systemPrompt, tokenCount: 250, estimatedTokenCount: true, content: "a"),
        ], limit: 1000)
        let lanes = RiverLayout.lanes(from: snap)
        XCTAssertEqual(lanes.first?.proportion ?? 0, 0.25, accuracy: 0.0001)
    }

    func testProportionFallsBackToTotalTokensWhenNoLimit() {
        let snap = snapshot(items: [
            ContextItem(category: .systemPrompt, tokenCount: 50, estimatedTokenCount: true, content: "a"),
            ContextItem(category: .toolOutputs, tokenCount: 50, estimatedTokenCount: true, content: "b"),
        ], limit: nil)
        let lanes = RiverLayout.lanes(from: snap)
        XCTAssertEqual(lanes.first { $0.id == .systemPrompt }?.proportion ?? 0, 0.5, accuracy: 0.0001)
    }

    func testLanesPreserveDisplayOrder() {
        let snap = snapshot(items: [
            ContextItem(category: .toolOutputs, tokenCount: 10, estimatedTokenCount: true, content: "a"),
            ContextItem(category: .systemPrompt, tokenCount: 10, estimatedTokenCount: true, content: "b"),
            ContextItem(category: .toolDefinitions, tokenCount: 10, estimatedTokenCount: true, content: "c"),
        ], limit: 100)
        let lanes = RiverLayout.lanes(from: snap)
        XCTAssertEqual(lanes.map { $0.id }, [.systemPrompt, .toolDefinitions, .toolOutputs])
    }

    func testEmptyDenominatorReturnsNoLanes() {
        let snap = ContextSnapshot(runID: UUID(), items: [], totalTokens: 0, contextLimit: nil)
        XCTAssertTrue(RiverLayout.lanes(from: snap).isEmpty)
    }
}
```

- [x] **Step 3: Run test to verify it fails, then passes**

Run: `swift test --package-path Packages/ContextScopeVisualization --filter RiverLayoutTests`
Expected: First, if the directory was missing it now compiles; `RiverLayout.lanes` already exists so the tests should PASS (5 tests). If any fail, the bug is in the test expectations — re-derive proportions from the source (`Double(count) / denominator`).

- [x] **Step 4: Commit**

```bash
git add Packages/ContextScopeVisualization/Package.swift Packages/ContextScopeVisualization/Tests/ContextScopeVisualizationTests/RiverLayoutTests.swift
git commit -m "test(viz): add RiverLayout.lanes coverage and test target"
```

---

## Task 5: `ProxyServer` start/stop lifecycle tests

**Files:**
- Test: `Packages/ContextScopeCapture/Tests/ContextScopeCaptureTests/ProxyServerLifecycleTests.swift`

We test that the server starts, that `/health` answers over a real TCP socket, and that stop is idempotent. We use a non-default port (`4329`) to avoid clashing with a running app instance.

- [x] **Step 1: Write the failing test**

Create `Packages/ContextScopeCapture/Tests/ContextScopeCaptureTests/ProxyServerLifecycleTests.swift`:

```swift
import XCTest
import ContextScopeCore
@testable import ContextScopeCapture

final class ProxyServerLifecycleTests: XCTestCase {
    func testStartThenStopDoesNotThrow() async throws {
        let server = ProxyServer(
            port: 4329,
            upstreamBaseURL: URL(string: "https://api.openai.com")!,
            apiKey: "test"
        )
        try await server.start()
        await server.stop()
    }

    func testHealthEndpointRespondsOK() async throws {
        let server = ProxyServer(
            port: 4330,
            upstreamBaseURL: URL(string: "https://api.openai.com")!,
            apiKey: "test"
        )
        try await server.start()
        defer { Task { await server.stop() } }

        var request = URLRequest(url: URL(string: "http://127.0.0.1:4330/health")!)
        request.timeoutInterval = 5
        let (data, response) = try await URLSession.shared.data(for: request)
        let http = try XCTUnwrap(response as? HTTPURLResponse)
        XCTAssertEqual(http.statusCode, 200)
        XCTAssertEqual(String(data: data, encoding: .utf8), #"{"status":"ok"}"#)
    }

    func testDoubleStopIsSafe() async throws {
        let server = ProxyServer(
            port: 4331,
            upstreamBaseURL: URL(string: "https://api.openai.com")!,
            apiKey: "test"
        )
        try await server.start()
        await server.stop()
        await server.stop()
    }

    func testInvalidPortThrows() async {
        let server = ProxyServer(
            port: 0,
            upstreamBaseURL: URL(string: "https://api.openai.com")!,
            apiKey: "test"
        )
        do {
            try await server.start()
            XCTFail("Expected start() to throw for port 0")
            await server.stop()
        } catch {
            // NWEndpoint.Port(rawValue: 0) is nil -> ProxyError.invalidPort
            XCTAssertTrue(error is ProxyError)
        }
    }
}
```

- [x] **Step 2: Run test to verify it fails or passes**

Run: `swift test --package-path Packages/ContextScopeCapture --filter ProxyServerLifecycleTests`
Expected: These exercise existing behavior and should PASS (4 tests). If the macOS test runner prompts for an incoming-connection firewall permission, accept it; on CI the `macos-14` runner allows local listeners without a prompt.

Note: `ProxyServer.start()` for port 0 throws `ProxyError.invalidPort(0)` because `NWEndpoint.Port(rawValue: 0)` returns `nil`. Confirm this matches the source in `ProxyServer.swift`.

- [x] **Step 3: No implementation change needed**

`ProxyServer` already implements start/stop and `/health`. No edit required.

- [x] **Step 4: Commit**

```bash
git add Packages/ContextScopeCapture/Tests/ContextScopeCaptureTests/ProxyServerLifecycleTests.swift
git commit -m "test(capture): add ProxyServer start/stop lifecycle coverage"
```

---

## Task 6: `KeychainStore` — SecItem-backed API key (app target test)

**Files:**
- Modify: `Package.swift` (add app test target)
- Create: `App/ContextScopeApp/Sources/KeychainStore.swift`
- Test: `App/ContextScopeApp/Tests/ContextScopeAppTests/KeychainStoreTests.swift`

The root `Package.swift` currently has no test target for the app. We add one so `KeychainStore` can be tested. The store uses a generic password item keyed by service + account.

- [x] **Step 1: Add the app test target to the root manifest**

In `Package.swift`, replace the closing of the `targets:` array. Change:

```swift
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
```

to:

```swift
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
        .testTarget(
            name: "ContextScopeAppTests",
            dependencies: ["ContextScopeApp"],
            path: "App/ContextScopeApp/Tests/ContextScopeAppTests"
        ),
    ]
)
```

- [x] **Step 2: Write the failing test**

Create `App/ContextScopeApp/Tests/ContextScopeAppTests/KeychainStoreTests.swift`:

```swift
import XCTest
@testable import ContextScopeApp

final class KeychainStoreTests: XCTestCase {
    // Use a unique account per run so tests never collide with a real key.
    private var store: KeychainStore!
    private let account = "test-\(UUID().uuidString)"

    override func setUp() {
        super.setUp()
        store = KeychainStore(service: "com.contextscope.tests", account: account)
        store.delete()
    }

    override func tearDown() {
        store.delete()
        super.tearDown()
    }

    func testReadReturnsNilWhenAbsent() {
        XCTAssertNil(store.read())
    }

    func testWriteThenReadRoundTrips() {
        XCTAssertTrue(store.write("sk-secret-123"))
        XCTAssertEqual(store.read(), "sk-secret-123")
    }

    func testWriteOverwritesExistingValue() {
        XCTAssertTrue(store.write("first"))
        XCTAssertTrue(store.write("second"))
        XCTAssertEqual(store.read(), "second")
    }

    func testDeleteRemovesValue() {
        XCTAssertTrue(store.write("to-delete"))
        store.delete()
        XCTAssertNil(store.read())
    }
}
```

- [x] **Step 3: Run test to verify it fails**

Run: `swift test --filter KeychainStoreTests`
Expected: FAIL — `cannot find 'KeychainStore' in scope`.

- [x] **Step 4: Write the implementation**

Create `App/ContextScopeApp/Sources/KeychainStore.swift`:

```swift
import Foundation
import Security

/// Stores a single secret (the upstream API key) in the macOS Keychain as a
/// generic password item. Replaces the prototype's UserDefaults storage.
struct KeychainStore {
    let service: String
    let account: String

    init(service: String = "com.contextscope.app", account: String = "upstreamAPIKey") {
        self.service = service
        self.account = account
    }

    /// Read the stored secret, or nil if absent.
    func read() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
    }

    /// Write (insert or update) the secret. Returns true on success.
    @discardableResult
    func write(_ value: String) -> Bool {
        let data = Data(value.utf8)
        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        // Try update first; if the item does not exist, add it.
        let attributes: [String: Any] = [kSecValueData as String: data]
        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return true
        }
        if updateStatus == errSecItemNotFound {
            var addQuery = baseQuery
            addQuery[kSecValueData as String] = data
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
        }
        return false
    }

    /// Remove the secret. Safe to call when nothing is stored.
    func delete() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
```

- [x] **Step 5: Run test to verify it passes**

Run: `swift test --filter KeychainStoreTests`
Expected: PASS (4 tests).

Note: macOS Keychain access from an unsigned `swift test` binary may emit a warning but generic-password round-trips work in the login keychain on `macos-14`. If CI fails here with `errSecMissingEntitlement`, add `-DSKIP_KEYCHAIN_TESTS` handling is NOT needed — instead the sign step in Task 11 covers the app; tests run against the login keychain which does not require entitlements.

- [x] **Step 6: Commit**

```bash
git add Package.swift App/ContextScopeApp/Sources/KeychainStore.swift App/ContextScopeApp/Tests/ContextScopeAppTests/KeychainStoreTests.swift
git commit -m "feat(app): add KeychainStore for API key with tests"
```

---

## Task 7: Migrate API key reads/writes to Keychain

**Files:**
- Modify: `App/ContextScopeApp/Sources/AppState.swift` (lines around 71-85)
- Modify: `App/ContextScopeApp/Sources/OnboardingView.swift` (lines 167-173)

- [x] **Step 1: Add a shared keychain instance and a one-time migration to AppState**

In `App/ContextScopeApp/Sources/AppState.swift`, add a property after `private var proxy: ProxyServer?` (line 33):

```swift
    private let keychain = KeychainStore()
```

Then replace the `init()` body (lines 35-38):

```swift
    init() {
        // Show onboarding on first launch
        showOnboarding = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
    }
```

with:

```swift
    init() {
        // Show onboarding on first launch
        showOnboarding = !UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        // One-time migration: move any legacy plaintext key out of UserDefaults.
        if let legacy = UserDefaults.standard.string(forKey: "apiKey"), !legacy.isEmpty {
            keychain.write(legacy)
            UserDefaults.standard.removeObject(forKey: "apiKey")
        }
    }
```

- [x] **Step 2: Read the key from Keychain in startProxy**

In `App/ContextScopeApp/Sources/AppState.swift`, change line 74:

```swift
        let apiKey = UserDefaults.standard.string(forKey: "apiKey") ?? ""
```

to:

```swift
        let apiKey = keychain.read() ?? ""
```

- [x] **Step 3: Write the key to Keychain in onboarding**

In `App/ContextScopeApp/Sources/OnboardingView.swift`, replace `saveSettings()` (lines 167-173):

```swift
    private func saveSettings() {
        UserDefaults.standard.set(upstreamURL, forKey: "upstreamBaseURL")
        // NOTE: In production, apiKey should be stored in Keychain.
        // For this prototype it's stored in UserDefaults with a clear privacy warning.
        // TODO: replace with SecItemAdd/CopyMatching Keychain calls.
        UserDefaults.standard.set(apiKey, forKey: "apiKey")
    }
```

with:

```swift
    private func saveSettings() {
        UserDefaults.standard.set(upstreamURL, forKey: "upstreamBaseURL")
        // API key is stored in the macOS Keychain (generic password), never UserDefaults.
        if !apiKey.isEmpty {
            KeychainStore().write(apiKey)
        }
    }
```

- [x] **Step 4: Verify the app builds**

Run: `swift build`
Expected: Builds with no errors.

- [x] **Step 5: Commit**

```bash
git add App/ContextScopeApp/Sources/AppState.swift App/ContextScopeApp/Sources/OnboardingView.swift
git commit -m "feat(app): store API key in Keychain with UserDefaults migration"
```

---

## Task 8: `LiveCaptureCoordinator` — bridge AsyncStream into AppState

**Files:**
- Create: `App/ContextScopeApp/Sources/LiveCaptureCoordinator.swift`
- Modify: `App/ContextScopeApp/Sources/AppState.swift`

The Swift Concurrency pattern: `ProxyServer.events` is a `nonisolated let` `AsyncStream<TraceEvent>` on an actor — reading the property is fine from any context, and iterating it does not touch actor state. We start a detached-but-MainActor `Task` (created from a `@MainActor` method, so its body is MainActor-isolated) and `for await` the events, mutating `@Published` properties directly. We seed the builder by parsing the request body on the first `.requestStart`-adjacent `.requestComplete`/`streamChunk`; since `ProxyServer` does not currently surface the parsed request, the coordinator parses tokens incrementally from stream payloads and seeds request items lazily from the most recent request the proxy forwarded. To get request items, we add a lightweight `.requestStart` payload carrying the raw request body.

- [x] **Step 1: Enrich the requestStart event with the request body in ProxyServer**

In `Packages/ContextScopeCapture/Sources/ContextScopeCapture/ProxyServer.swift`, change line 122:

```swift
            eventContinuation.yield(TraceEvent(runID: runID, kind: .requestStart, payload: Data()))
```

to:

```swift
            eventContinuation.yield(TraceEvent(runID: runID, kind: .requestStart, payload: parsed.body ?? Data()))
```

- [x] **Step 2: Build the coordinator**

Create `App/ContextScopeApp/Sources/LiveCaptureCoordinator.swift`:

```swift
import Foundation
import ContextScopeCore
import ContextScopeCapture

/// Drains a ProxyServer's `events` AsyncStream on the main actor and folds them
/// into a live ContextSnapshot, invoking `onSnapshot` after each update.
@MainActor
final class LiveCaptureCoordinator {
    private var task: Task<Void, Never>?
    private var builder: LiveSnapshotBuilder?
    private let adapter = OpenAIAdapter()
    private let registry = ModelRegistry()

    private let onSnapshot: (ContextSnapshot) -> Void

    init(onSnapshot: @escaping (ContextSnapshot) -> Void) {
        self.onSnapshot = onSnapshot
    }

    /// Begin consuming events from the given stream. The closure runs on the
    /// main actor, so it is safe to mutate @Published state inside `onSnapshot`.
    func start(events: AsyncStream<TraceEvent>) {
        task?.cancel()
        builder = nil
        task = Task { @MainActor in
            for await event in events {
                self.handle(event)
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        builder = nil
    }

    private func handle(_ event: TraceEvent) {
        switch event.kind {
        case .requestStart:
            let items = parseRequestItems(from: event.payload)
            let limit = contextLimit(from: event.payload)
            var b = LiveSnapshotBuilder(runID: event.runID, contextLimit: limit)
            b.seed(items: items)
            builder = b
            onSnapshot(b.snapshot())
        case .streamChunk, .toolCall, .toolResult:
            guard var b = builder, b.runID == event.runID else { return }
            b.apply(event: event)
            builder = b
            onSnapshot(b.snapshot())
        case .requestComplete, .error:
            if let b = builder, b.runID == event.runID {
                onSnapshot(b.snapshot())
            }
        }
    }

    private func parseRequestItems(from body: Data) -> [ContextItem] {
        guard !body.isEmpty else { return [] }
        let request = HTTPRequest(method: "POST", path: "/v1/chat/completions", headers: [:], body: body)
        return (try? adapter.parseRequest(request))?.contextItems ?? []
    }

    private func contextLimit(from body: Data) -> Int? {
        guard !body.isEmpty,
              let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
              let model = json["model"] as? String else { return nil }
        return registry.entry(for: model)?.contextLimit
    }
}
```

- [x] **Step 3: Wire the coordinator into AppState**

In `App/ContextScopeApp/Sources/AppState.swift`, add a published live snapshot after the `selectedSession` property (line 28):

```swift
    @Published var liveSnapshot: ContextSnapshot?
    @Published var liveTokenCount: Int = 0
```

Add a coordinator property after `private let keychain = KeychainStore()`:

```swift
    private var captureCoordinator: LiveCaptureCoordinator?
```

In `startProxy()`, after `try await server.start()` and before `proxyRunning = true`, insert the subscription. Replace the success branch body. Change:

```swift
        do {
            try await server.start()
            proxyRunning = true
            proxyError = nil
        } catch {
```

to:

```swift
        do {
            try await server.start()
            let coordinator = LiveCaptureCoordinator { [weak self] snapshot in
                self?.liveSnapshot = snapshot
                self?.liveTokenCount = snapshot.totalTokens
            }
            coordinator.start(events: server.events)
            captureCoordinator = coordinator
            proxyRunning = true
            proxyError = nil
        } catch {
```

In `stopProxy()`, replace:

```swift
    func stopProxy() async {
        await proxy?.stop()
        proxy = nil
        proxyRunning = false
    }
```

with:

```swift
    func stopProxy() async {
        captureCoordinator?.stop()
        captureCoordinator = nil
        await proxy?.stop()
        proxy = nil
        proxyRunning = false
        liveSnapshot = nil
        liveTokenCount = 0
    }
```

- [x] **Step 4: Verify the app builds**

Run: `swift build`
Expected: Builds with no errors.

- [x] **Step 5: Commit**

```bash
git add App/ContextScopeApp/Sources/LiveCaptureCoordinator.swift App/ContextScopeApp/Sources/AppState.swift Packages/ContextScopeCapture/Sources/ContextScopeCapture/ProxyServer.swift
git commit -m "feat(app): bridge ProxyServer events into live ContextSnapshot on AppState"
```

---

## Task 9: Show the live snapshot in ContextRiverView

**Files:**
- Modify: `App/ContextScopeApp/Sources/ContextRiverView.swift`

The view currently derives everything from a single private computed property at line 11:

```swift
    private var snapshot: ContextSnapshot? { appState.replayEngine.currentSnapshot }
```

The body (`if let snap = snapshot`), `updateLanes()` (which reads `snapshot`), and an `.onChange(of: appState.replayEngine.currentFrameIndex)` all flow from that one property. So we only need to (a) make `snapshot` prefer the live capture, and (b) also recompute lanes when `liveSnapshot` changes.

- [x] **Step 1: Make `snapshot` prefer the live capture**

In `App/ContextScopeApp/Sources/ContextRiverView.swift`, replace line 11:

```swift
    private var snapshot: ContextSnapshot? { appState.replayEngine.currentSnapshot }
```

with:

```swift
    /// When the proxy is running and has captured a request, show the live
    /// snapshot; otherwise fall back to the replay engine's current frame.
    private var snapshot: ContextSnapshot? {
        if appState.proxyRunning, let live = appState.liveSnapshot {
            return live
        }
        return appState.replayEngine.currentSnapshot
    }
```

- [x] **Step 2: Recompute lanes when the live snapshot changes**

In the same file, find the modifier block on the `ScrollView` (around line 38):

```swift
        .onChange(of: appState.replayEngine.currentFrameIndex) { _, _ in
            updateLanes()
        }
        .onAppear { updateLanes() }
```

Replace it with:

```swift
        .onChange(of: appState.replayEngine.currentFrameIndex) { _, _ in
            updateLanes()
        }
        .onChange(of: appState.liveTokenCount) { _, _ in
            updateLanes()
        }
        .onAppear { updateLanes() }
```

`updateLanes()` already reads the `snapshot` computed property and assigns `animatedLanes = RiverLayout.lanes(from: snap)`, so no further change is needed there.

- [x] **Step 3: Verify the app builds**

Run: `swift build`
Expected: Builds with no errors.

- [x] **Step 4: Manual smoke check**

Run (in one terminal): `swift run ContextScopeApp`
In the app: complete onboarding with a real key, Start Proxy, then in another terminal:
```bash
curl -N http://127.0.0.1:4319/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4o","stream":true,"messages":[{"role":"system","content":"You are concise."},{"role":"user","content":"Say hi in 3 words."}]}'
```
Expected: The Context River animates with a system-prompt lane plus a growing tool-outputs lane as chunks stream. Stop the app with Ctrl-C in the first terminal.

- [x] **Step 5: Commit**

```bash
git add App/ContextScopeApp/Sources/ContextRiverView.swift
git commit -m "feat(app): render live captured snapshot in ContextRiverView"
```

---

## Task 10: Menu bar extra

**Files:**
- Create: `App/ContextScopeApp/Sources/MenuBarView.swift`
- Modify: `App/ContextScopeApp/Sources/ContextScopeApp.swift`

SwiftUI's `MenuBarExtra` scene gives us an `NSStatusItem` with zero Xcode-project setup — it works in a pure-SPM executable on macOS 14. We use the `.menu` style so the status item shows a dropdown of controls.

- [x] **Step 1: Build the menu content view**

Create `App/ContextScopeApp/Sources/MenuBarView.swift`:

```swift
import SwiftUI
import AppKit

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Button(appState.proxyRunning ? "Stop Proxy" : "Start Proxy") {
            Task { await appState.toggleProxy() }
        }
        .keyboardShortcut("p", modifiers: [.command, .shift])

        if appState.proxyRunning {
            Text("Listening on \(appState.proxyBaseURL)")
            if appState.liveTokenCount > 0 {
                Text("Live context: \(appState.liveTokenCount) tokens")
            } else {
                Text("Waiting for requests…")
            }
        } else {
            Text("Proxy stopped")
        }

        Divider()

        Button("Copy Base URL") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(appState.proxyBaseURL, forType: .string)
        }

        Divider()

        Button("Quit ContextScope") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: [.command])
    }
}

/// The status item's title/icon. Shows a filled dot when running and the live
/// token count when a request is in flight.
struct MenuBarLabel: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: appState.proxyRunning ? "circle.fill" : "circle")
            if appState.proxyRunning && appState.liveTokenCount > 0 {
                Text("\(appState.liveTokenCount)")
            }
        }
    }
}
```

- [x] **Step 2: Add the MenuBarExtra scene to the app**

In `App/ContextScopeApp/Sources/ContextScopeApp.swift`, add a second scene after the `WindowGroup { ... }` block's closing modifiers (after the `.commands { ... }` block, still inside `var body: some Scene`). Change the end of `body`:

```swift
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandMenu("Proxy") {
                Button(appState.proxyRunning ? "Stop Proxy" : "Start Proxy") {
                    Task { await appState.toggleProxy() }
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])

                Divider()

                Button("Copy Base URL") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(appState.proxyBaseURL, forType: .string)
                }
            }
        }
    }
}
```

to:

```swift
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandMenu("Proxy") {
                Button(appState.proxyRunning ? "Stop Proxy" : "Start Proxy") {
                    Task { await appState.toggleProxy() }
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])

                Divider()

                Button("Copy Base URL") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(appState.proxyBaseURL, forType: .string)
                }
            }
        }

        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
        } label: {
            MenuBarLabel()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.menu)
    }
}
```

- [x] **Step 3: Verify the app builds**

Run: `swift build`
Expected: Builds with no errors.

- [x] **Step 4: Manual smoke check**

Run: `swift run ContextScopeApp`
Expected: A status item appears in the macOS menu bar. Clicking it shows Start/Stop Proxy, the base URL, and Copy Base URL / Quit. Toggling the proxy from the menu updates the main window's status bar. Quit via the menu item.

- [x] **Step 5: Commit**

```bash
git add App/ContextScopeApp/Sources/MenuBarView.swift App/ContextScopeApp/Sources/ContextScopeApp.swift
git commit -m "feat(app): add menu bar extra with proxy status and quick actions"
```

---

## Task 11: Entitlements file + code-signing for the SPM executable

**Files:**
- Create: `App/ContextScopeApp/Resources/ContextScopeApp.entitlements`
- Create: `Scripts/sign.sh`

SPM executables have no Xcode entitlements build phase. The pattern is: build normally, then `codesign` the produced binary with an entitlements plist using an ad-hoc identity (`-`). The proxy needs `network.server` (to listen) and `network.client` (to forward upstream). We do NOT enable the App Sandbox in the entitlements file, because a sandboxed unsigned dev binary cannot open a listening socket without a provisioning profile; for local development the network entitlements + ad-hoc signing are sufficient. (App Store distribution would later require the sandbox + proper signing identity — out of scope for Phase 2.)

- [x] **Step 1: Create the entitlements plist**

Create `App/ContextScopeApp/Resources/ContextScopeApp.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.network.server</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
</plist>
```

- [x] **Step 2: Create the signing script**

Create `Scripts/sign.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Ad-hoc code-sign the built ContextScopeApp executable with network
# entitlements. SPM executables have no Xcode entitlements phase, so we apply
# them post-build. Run after `swift build`.

CONFIG="${1:-debug}"
ENTITLEMENTS="App/ContextScopeApp/Resources/ContextScopeApp.entitlements"

BIN_DIR="$(swift build --configuration "$CONFIG" --show-bin-path)"
BINARY="$BIN_DIR/ContextScopeApp"

if [ ! -f "$BINARY" ]; then
  echo "Error: $BINARY not found. Run 'swift build --configuration $CONFIG' first." >&2
  exit 1
fi

echo "==> Signing $BINARY"
codesign --force --sign - \
  --entitlements "$ENTITLEMENTS" \
  --options runtime \
  "$BINARY"

echo "==> Verifying entitlements"
codesign --display --entitlements - "$BINARY"

echo "Signed."
```

- [x] **Step 3: Make the script executable**

Run: `chmod +x Scripts/sign.sh`
Expected: No output.

- [x] **Step 4: Verify build + sign works end to end**

Run:
```bash
swift build && ./Scripts/sign.sh debug
```
Expected: Build succeeds; the script prints the two network entitlements under "Verifying entitlements" and ends with "Signed."

- [x] **Step 5: Commit**

```bash
git add App/ContextScopeApp/Resources/ContextScopeApp.entitlements Scripts/sign.sh
git commit -m "build: add network entitlements and ad-hoc codesign script for SPM executable"
```

---

## Task 12: Update `Scripts/test.sh` to use the root package

**Files:**
- Modify: `Scripts/test.sh`

The per-package loop misses the new app and visualization test targets. Running `swift test` from the root builds every dependency and runs all test targets in one pass.

- [x] **Step 1: Replace the test script body**

Replace the entire contents of `Scripts/test.sh` with:

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "==> ContextScope test suite (root package)"
echo ""

# The root Package.swift aggregates all five library packages plus the app,
# so a single `swift test` builds and runs every test target.
swift test

echo ""
echo "All tests passed."
```

- [x] **Step 2: Run the full suite**

Run: `./Scripts/test.sh`
Expected: All test targets run and pass (Core, Capture, Storage, DemoData, Visualization, App). PASS.

- [x] **Step 3: Commit**

```bash
git add Scripts/test.sh
git commit -m "test: run full suite from root package in test.sh"
```

---

## Task 13: Update CI to build root package, test, and sign

**Files:**
- Modify: `.github/workflows/ci.yml`

`macos-14` runners ship Swift 5.10+, which builds this swift-tools-5.9 package. We pin Xcode 15.4 (already used), build the root package, run the full test suite, and run the sign step to catch entitlement/codesign regressions.

- [x] **Step 1: Replace the workflow**

Replace the entire contents of `.github/workflows/ci.yml` with:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build-and-test:
    name: Build & Test
    runs-on: macos-14

    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode_15.4.app

      - name: Swift version
        run: swift --version

      - name: Build (root package)
        run: swift build

      - name: Test (root package)
        run: swift test

      - name: Code-sign with entitlements
        run: ./Scripts/sign.sh debug
```

- [x] **Step 2: Validate the YAML locally**

Run: `swift build && swift test && ./Scripts/sign.sh debug`
Expected: All three succeed locally, mirroring the CI steps. PASS.

- [x] **Step 3: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: build and test from root package, verify entitlements signing"
```

---

## Task 14: Final full-suite verification

**Files:** none (verification only)

- [x] **Step 1: Clean build + full test + sign**

Run:
```bash
swift package clean && swift build && swift test && ./Scripts/sign.sh debug
```
Expected: Build succeeds, every test target passes, signing prints the two network entitlements.

- [x] **Step 2: Manual live-capture confirmation**

Run: `swift run ContextScopeApp`, complete onboarding, Start Proxy from the menu bar extra, send the streaming `curl` from Task 9 Step 4, and confirm the river animates and the menu bar shows a live token count.

- [x] **Step 3: Confirm no plaintext key remains**

Run: `defaults read com.contextscope.app apiKey 2>&1 || true`
Expected: `does not exist` (the migration removed it; the key now lives in the Keychain).

---

## Self-Review Notes

- **Spec coverage:** Live proxy→UI (Tasks 1, 8, 9), Keychain (Tasks 6, 7), Menu bar (Task 10), Entitlements (Task 11), Tests for adapter/river/classifier/proxy (Tasks 2, 3, 4, 5), CI (Tasks 12, 13). All six spec items have tasks.
- **Concurrency:** `ProxyServer.events` is a `let` on the actor, readable from `startProxy()` without `await`. `LiveCaptureCoordinator.start` opens a `Task { @MainActor in ... }` whose body is MainActor-isolated, so `onSnapshot` mutating `@Published` is safe; no data races.
- **Entitlements:** Applied post-build via ad-hoc `codesign --entitlements`, the only mechanism available to a pure-SPM executable. Sandbox deliberately omitted for local dev.
- **Keychain:** Uses `SecItemUpdate` then `SecItemAdd` on `errSecItemNotFound`, `SecItemCopyMatching` for read, `SecItemDelete` for delete — the standard generic-password pattern.
- **Type consistency:** `LiveSnapshotBuilder` API (`seed(items:)`, `apply(event:)`, `snapshot()`, `runID`, `contextLimit`) is identical across Tasks 1 and 8. `KeychainStore` API (`read`, `write`, `delete`) is identical across Tasks 6 and 7. `liveSnapshot`/`liveTokenCount` published names match across Tasks 8, 9, 10.
- **ReplayEngine accessor:** Confirmed against source — `ReplayEngine` exposes `@Published currentSnapshot: ContextSnapshot?` and `currentFrameIndex: Int`. `ContextRiverView`'s private `snapshot` property (line 11) already reads `currentSnapshot`; Task 9 edits exactly that property plus the existing `.onChange`/`updateLanes()` flow.

---

**Execution Handoff**

Plan complete and saved to `docs/superpowers/plans/2026-06-07-phase2-live-proxy-menubar.md`. Two execution options:

1. **Subagent-Driven (recommended)** — dispatch a fresh subagent per task, review between tasks, fast iteration.
2. **Inline Execution** — execute tasks in this session using executing-plans, batch execution with checkpoints.

Which approach?
