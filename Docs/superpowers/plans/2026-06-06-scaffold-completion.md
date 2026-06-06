# ContextScope Scaffold Completion Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the open-source repository scaffold with community health files, GitHub templates, CI, all five Swift package manifests, stub Swift sources, developer scripts, docs, and examples.

**Architecture:** All content is static scaffold — markdown, SPM manifests, stub Swift sources (type declarations + `fatalError("unimplemented")` where bodies are required), and Bash scripts. No tests are needed because nothing is algorithmic yet; tests come when each stub is implemented. Git commit per logical group.

**Tech Stack:** Swift 5.9 / SPM, GitHub Actions (ubuntu-latest), Bash, Markdown.

---

## File Map

```
CODE_OF_CONDUCT.md
SECURITY.md
ROADMAP.md
.github/
  ISSUE_TEMPLATE/bug_report.md
  ISSUE_TEMPLATE/feature_request.md
  pull_request_template.md
  workflows/ci.yml
Packages/
  ContextScopeCore/
    Package.swift
    Sources/ContextScopeCore/
      Models/Project.swift
      Models/Session.swift
      Models/Run.swift
      Models/ContextSnapshot.swift
      Models/TraceEvent.swift
      Models/ContextItem.swift
      Protocols/TokenCounting.swift
      Protocols/EventSource.swift
      Protocols/StorageProvider.swift
      Protocols/ProviderAdapter.swift
      TokenEstimator/TokenEstimator.swift
      TokenEstimator/ModelRegistry.swift
  ContextScopeCapture/
    Package.swift
    Sources/ContextScopeCapture/
      ProxyServer.swift
      RequestInterceptor.swift
      UpstreamForwarder.swift
      StreamingParser.swift
      Sanitizer.swift
      ContextClassifier.swift
      Adapters/AdapterRegistry.swift
  ContextScopeStorage/
    Package.swift
    Sources/ContextScopeStorage/
      Database.swift
      Repositories/RunRepository.swift
      Repositories/SessionRepository.swift
      Export/TraceExporter.swift
  ContextScopeVisualization/
    Package.swift
    Sources/ContextScopeVisualization/
      ContextRiver/RiverLayout.swift
      ContextRiver/RiverLegendView.swift
      ContextRiver/CategoryStyle.swift
      ExecutionGraph/GraphLayout.swift
      TimelineReplay/ReplayEngine.swift
  ContextScopeDemoData/
    Package.swift
    Sources/ContextScopeDemoData/
      DemoSession.swift
      DemoScenarioRegistry.swift
      Fixtures/healthy_request.contextscope.json
      Fixtures/bloated_context.contextscope.json
      Fixtures/runaway_tool_loop.contextscope.json
Scripts/
  bootstrap.sh
  test.sh
  run-demo.sh
Docs/
  TraceFormat.md
  StarterIssues.md
  DemoRecordingGuide.md
  ArchitectureDecisions/ADR-001-embedded-http-server.md
  ArchitectureDecisions/ADR-002-sqlite-approach.md
  ArchitectureDecisions/ADR-003-animation-model.md
Examples/
  python/basic_chat.py
  nodejs/basic_chat.js
  curl/basic_chat.sh
  sample-traces/README.md
```

---

### Task 1: Community Health Files

**Files:**
- Create: `CODE_OF_CONDUCT.md`
- Create: `SECURITY.md`
- Create: `ROADMAP.md`

- [ ] **Step 1: Create CODE_OF_CONDUCT.md**

```markdown
# Code of Conduct

ContextScope follows the [Contributor Covenant 2.1](https://www.contributor-covenant.org/version/2/1/code_of_conduct/).

## Our Pledge

We as members, contributors, and leaders pledge to make participation in our community a harassment-free experience for everyone, regardless of age, body size, visible or invisible disability, ethnicity, sex characteristics, gender identity and expression, level of experience, education, socioeconomic status, nationality, personal appearance, race, caste, color, religion, or sexual identity and orientation.

We pledge to act and interact in ways that contribute to an open, welcoming, diverse, inclusive, and healthy community.

## Our Standards

Examples of behavior that contributes to a positive environment:

- Demonstrating empathy and kindness toward other people
- Being respectful of differing opinions, viewpoints, and experiences
- Giving and gracefully accepting constructive feedback
- Accepting responsibility and apologizing to those affected by our mistakes
- Focusing on what is best not just for us as individuals, but for the overall community

Examples of unacceptable behavior:

- The use of sexualized language or imagery, and sexual attention or advances of any kind
- Trolling, insulting or derogatory comments, and personal or political attacks
- Public or private harassment
- Publishing others' private information without explicit permission
- Other conduct which could reasonably be considered inappropriate in a professional setting

## Enforcement

Instances of abusive, harassing, or otherwise unacceptable behavior may be reported to the project maintainers at **ashutoshaggarwal98@gmail.com**. All complaints will be reviewed and investigated promptly and fairly.

Project maintainers have the right and responsibility to remove, edit, or reject comments, commits, code, issues, and other contributions that are not aligned with this Code of Conduct, and will communicate reasons for moderation decisions when appropriate.

## Attribution

This Code of Conduct is adapted from the [Contributor Covenant](https://www.contributor-covenant.org), version 2.1.
```

- [ ] **Step 2: Create SECURITY.md**

```markdown
# Security Policy

## Supported Versions

| Version | Supported |
|---|---|
| 0.x pre-release | Best effort |

ContextScope is pre-release software. Security fixes are applied to the `main` branch and released in the next tagged version.

## Threat Model

ContextScope is a **local-first** developer tool. The primary attack surfaces are:

- The local HTTP proxy (`127.0.0.1:4319` by default) accepting requests
- API key handling — keys pass through the proxy but must never be logged, stored in SQLite, or emitted to the UI
- The `.contextscope.json` export format — must redact secrets before writing
- The local SQLite database — file permissions must prevent other users on the same machine from reading it

Out of scope: vulnerabilities in upstream LLM providers, attacks requiring physical machine access.

## Reporting a Vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

Report privately via:

1. **GitHub Security Advisory:** [Open a private advisory](https://github.com/ashutosh160798/context-scope/security/advisories/new) (preferred)
2. **Email:** ashutoshaggarwal98@gmail.com — include "SECURITY" in the subject line

Please include:
- A description of the vulnerability and its potential impact
- Steps to reproduce or a proof-of-concept
- The version or commit hash you tested against

We aim to:
- Acknowledge receipt within **5 business days**
- Provide a fix or mitigation within **30 days** of confirmation

We will credit reporters in the release notes unless you prefer to remain anonymous.
```

- [ ] **Step 3: Create ROADMAP.md**

```markdown
# ContextScope Roadmap

This roadmap reflects current intent, not a contractual commitment. Priorities may shift based on contributor interest and user feedback.

---

## v0.1 — Proxy + Live Visualization (current target)

**Goal:** A working local proxy that captures OpenAI-compatible traffic and renders a live Context Pressure River.

| Feature | Status |
|---|---|
| OpenAI-compatible proxy (`POST /v1/chat/completions`) | 🚧 In development |
| Streaming SSE passthrough | 🚧 In development |
| Context Pressure River (animated, proportional) | 🚧 In development |
| Live Execution Graph (causal DAG) | 🚧 In development |
| Token accounting (exact from usage data; heuristic fallback) | 🚧 In development |
| Context warnings (70 / 85 / 95%, single-item >25%, bloated tools, duplicates) | 🚧 In development |
| Menu-bar utility (proxy on/off, context %, last latency) | 🚧 In development |
| Demo Mode (no API key required, three prerecorded scenarios) | 🚧 In development |
| Local SQLite persistence | 🚧 In development |
| API key stored in macOS Keychain | 🚧 In development |
| Secret redaction before export | 🚧 In development |
| Trace export / import (`.contextscope.json`) | 🚧 In development |

**Good first issues for v0.1:** See [StarterIssues.md](StarterIssues.md).

---

## v0.2 — Run Comparison

- Side-by-side run diff (context composition, token counts, latency)
- Improved tokenizer accuracy (tiktoken-compatible for GPT models)
- Run tagging and search

---

## v0.3 — OpenTelemetry Ingestion

- Accept OTLP traces from LLM frameworks (LangChain, LlamaIndex, etc.)
- Map OTLP spans to ContextScope runs and sessions
- No proxy required for OTLP sources

---

## v0.4 — Anthropic Native Format

- Parse Anthropic `/v1/messages` request/response format
- Streaming event types: `content_block_delta`, `input_json_delta`
- Tool use and tool result visualization for Claude models

---

## v0.5 — RAG Retrieval Visualization

- Visualize retrieval chunks as a distinct context category
- Show chunk count, combined token cost, and similarity scores where available
- Highlight retrieval pressure relative to conversation history

---

## v1.0 — Stable Plugin and Trace Schemas

- Stable `.contextscope.json` trace format with versioned schema
- Public `ProviderAdapter` plugin API (documented extension point for third-party adapters)
- Signed release and Homebrew cask

---

## Won't Do (explicitly out of scope)

- Cloud storage or sync — ContextScope is local-only by design
- Production alerting or fleet monitoring — use LangSmith, Langfuse, or similar
- Team workspaces
- Mobile or web clients
```

- [ ] **Step 4: Commit**

```bash
git add CODE_OF_CONDUCT.md SECURITY.md ROADMAP.md
git commit -m "docs: add CODE_OF_CONDUCT, SECURITY policy, and ROADMAP"
```

---

### Task 2: GitHub Templates and CI

**Files:**
- Create: `.github/ISSUE_TEMPLATE/bug_report.md`
- Create: `.github/ISSUE_TEMPLATE/feature_request.md`
- Create: `.github/pull_request_template.md`
- Create: `.github/workflows/ci.yml`

- [ ] **Step 1: Create bug report template**

```markdown
---
name: Bug report
about: Something isn't working
labels: bug
---

**Describe the bug**
A clear and concise description of what the bug is.

**To reproduce**
Steps to reproduce the behavior:
1. ...
2. ...

**Expected behavior**
What you expected to happen.

**Actual behavior**
What actually happened. Include any error messages or console output.

**Environment**
- macOS version:
- Xcode version:
- ContextScope version / commit:
- How are you routing traffic (SDK, curl, environment variable)?

**Additional context**
Attach a `.contextscope.json` trace export if possible (check that no real API keys are included before attaching).
```

- [ ] **Step 2: Create feature request template**

```markdown
---
name: Feature request
about: Suggest an improvement or new capability
labels: enhancement
---

**What problem does this solve?**
Describe the problem or gap in the current tool.

**Proposed solution**
Describe what you'd like to happen.

**Alternatives considered**
Any other approaches you considered and why you ruled them out.

**Is this on the roadmap?**
Check [ROADMAP.md](../../ROADMAP.md). If it is, link the relevant milestone.

**Additional context**
Screenshots, mockups, or related issues.
```

- [ ] **Step 3: Create PR template**

```markdown
## What does this PR do?

_One paragraph. Link the issue it closes if applicable: Closes #NNN._

## How to test

_Exact steps to verify the change works — not just "it builds."_

- [ ] `./Scripts/test.sh` passes
- [ ] Manually verified in the app / Demo Mode

## Checklist

- [ ] No third-party dependencies added without prior discussion
- [ ] `Sanitizer.swift` changes include a test proving the new pattern is redacted
- [ ] New `public` types in `Packages/` have unit tests
- [ ] No real API keys, user data, or third-party copyrighted content in fixtures or tests
```

- [ ] **Step 4: Create CI workflow**

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

      - name: Build ContextScopeCore
        run: swift build --package-path Packages/ContextScopeCore

      - name: Test ContextScopeCore
        run: swift test --package-path Packages/ContextScopeCore

      - name: Build ContextScopeCapture
        run: swift build --package-path Packages/ContextScopeCapture

      - name: Test ContextScopeCapture
        run: swift test --package-path Packages/ContextScopeCapture

      - name: Build ContextScopeStorage
        run: swift build --package-path Packages/ContextScopeStorage

      - name: Test ContextScopeStorage
        run: swift test --package-path Packages/ContextScopeStorage

      - name: Build ContextScopeDemoData
        run: swift build --package-path Packages/ContextScopeDemoData

      - name: Test ContextScopeDemoData
        run: swift test --package-path Packages/ContextScopeDemoData
```

Note: `ContextScopeVisualization` is excluded from CI because it imports SwiftUI, which requires a running display/simulator. It is tested locally only.

- [ ] **Step 5: Commit**

```bash
git add .github/
git commit -m "ci: add GitHub issue templates, PR template, and Actions workflow"
```

---

### Task 3: ContextScopeCore Package

**Files:** `Packages/ContextScopeCore/Package.swift` + 12 source stubs

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p Packages/ContextScopeCore/Sources/ContextScopeCore/Models
mkdir -p Packages/ContextScopeCore/Sources/ContextScopeCore/Protocols
mkdir -p Packages/ContextScopeCore/Sources/ContextScopeCore/TokenEstimator
mkdir -p Packages/ContextScopeCore/Tests/ContextScopeCoreTests
```

- [ ] **Step 2: Create Package.swift**

```swift
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
```

- [ ] **Step 3: Create Models/Project.swift**

```swift
import Foundation

public struct Project: Identifiable, Codable, Sendable {
    public let id: UUID
    public var name: String
    public let createdAt: Date

    public init(id: UUID = UUID(), name: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}
```

- [ ] **Step 4: Create Models/Session.swift**

```swift
import Foundation

public struct Session: Identifiable, Codable, Sendable {
    public let id: UUID
    public let projectID: UUID
    public let startedAt: Date
    public var endedAt: Date?

    public init(id: UUID = UUID(), projectID: UUID, startedAt: Date = Date()) {
        self.id = id
        self.projectID = projectID
        self.startedAt = startedAt
    }
}
```

- [ ] **Step 5: Create Models/ContextItem.swift**

```swift
import Foundation

public enum ContextCategory: String, Codable, CaseIterable, Sendable {
    case systemPrompt = "system_prompt"
    case conversationHistory = "conversation_history"
    case toolDefinitions = "tool_definitions"
    case retrievedContext = "retrieved_context"
    case toolOutputs = "tool_outputs"
    case other = "other"
}

public struct ContextItem: Identifiable, Codable, Sendable {
    public let id: UUID
    public let category: ContextCategory
    public let tokenCount: Int
    public let estimatedTokenCount: Bool
    public let content: String

    public init(
        id: UUID = UUID(),
        category: ContextCategory,
        tokenCount: Int,
        estimatedTokenCount: Bool,
        content: String
    ) {
        self.id = id
        self.category = category
        self.tokenCount = tokenCount
        self.estimatedTokenCount = estimatedTokenCount
        self.content = content
    }
}
```

- [ ] **Step 6: Create Models/ContextSnapshot.swift**

```swift
import Foundation

public struct ContextSnapshot: Codable, Sendable {
    public let runID: UUID
    public let timestamp: Date
    public let items: [ContextItem]
    public let totalTokens: Int
    public let contextLimit: Int?

    public var pressurePercent: Double? {
        guard let limit = contextLimit, limit > 0 else { return nil }
        return Double(totalTokens) / Double(limit) * 100
    }

    public init(
        runID: UUID,
        timestamp: Date = Date(),
        items: [ContextItem],
        totalTokens: Int,
        contextLimit: Int? = nil
    ) {
        self.runID = runID
        self.timestamp = timestamp
        self.items = items
        self.totalTokens = totalTokens
        self.contextLimit = contextLimit
    }
}
```

- [ ] **Step 7: Create Models/TraceEvent.swift**

```swift
import Foundation

public enum TraceEventKind: String, Codable, Sendable {
    case requestStart = "request_start"
    case streamChunk = "stream_chunk"
    case toolCall = "tool_call"
    case toolResult = "tool_result"
    case requestComplete = "request_complete"
    case error = "error"
}

public struct TraceEvent: Identifiable, Codable, Sendable {
    public let id: UUID
    public let runID: UUID
    public let kind: TraceEventKind
    public let timestamp: Date
    public let payload: Data

    public init(
        id: UUID = UUID(),
        runID: UUID,
        kind: TraceEventKind,
        timestamp: Date = Date(),
        payload: Data
    ) {
        self.id = id
        self.runID = runID
        self.kind = kind
        self.timestamp = timestamp
        self.payload = payload
    }
}
```

- [ ] **Step 8: Create Models/Run.swift**

```swift
import Foundation

public struct Run: Identifiable, Codable, Sendable {
    public let id: UUID
    public let sessionID: UUID
    public let model: String
    public let requestedAt: Date
    public var completedAt: Date?
    public let contextItems: [ContextItem]
    public var totalInputTokens: Int
    public var totalOutputTokens: Int
    public let inputTokensEstimated: Bool

    public init(
        id: UUID = UUID(),
        sessionID: UUID,
        model: String,
        requestedAt: Date = Date(),
        contextItems: [ContextItem],
        totalInputTokens: Int,
        totalOutputTokens: Int = 0,
        inputTokensEstimated: Bool
    ) {
        self.id = id
        self.sessionID = sessionID
        self.model = model
        self.requestedAt = requestedAt
        self.contextItems = contextItems
        self.totalInputTokens = totalInputTokens
        self.totalOutputTokens = totalOutputTokens
        self.inputTokensEstimated = inputTokensEstimated
    }
}
```

- [ ] **Step 9: Create Protocols/TokenCounting.swift**

```swift
public protocol TokenCounting: Sendable {
    func countTokens(in text: String, model: String) -> Int
    func isExact(for model: String) -> Bool
}
```

- [ ] **Step 10: Create Protocols/EventSource.swift**

```swift
public protocol EventSource: Sendable {
    var events: AsyncStream<TraceEvent> { get }
}
```

- [ ] **Step 11: Create Protocols/StorageProvider.swift**

```swift
import Foundation

public protocol StorageProvider: Sendable {
    func save(run: Run) async throws
    func fetchRuns(for sessionID: UUID) async throws -> [Run]
    func save(session: Session) async throws
    func fetchSessions(for projectID: UUID) async throws -> [Session]
    func deleteAll() async throws
}
```

- [ ] **Step 12: Create Protocols/ProviderAdapter.swift**

```swift
import Foundation

public struct HTTPRequest: Sendable {
    public let method: String
    public let path: String
    public let headers: [String: String]
    public let body: Data?

    public init(method: String, path: String, headers: [String: String], body: Data?) {
        self.method = method
        self.path = path
        self.headers = headers
        self.body = body
    }
}

public struct HTTPResponse: Sendable {
    public let statusCode: Int
    public let headers: [String: String]
    public let body: Data?

    public init(statusCode: Int, headers: [String: String], body: Data?) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
    }
}

public struct ParsedRequest: Sendable {
    public let model: String
    public let contextItems: [ContextItem]
    public let raw: HTTPRequest

    public init(model: String, contextItems: [ContextItem], raw: HTTPRequest) {
        self.model = model
        self.contextItems = contextItems
        self.raw = raw
    }
}

public struct ParsedResponse: Sendable {
    public let inputTokens: Int?
    public let outputTokens: Int?
    public let raw: HTTPResponse

    public init(inputTokens: Int?, outputTokens: Int?, raw: HTTPResponse) {
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.raw = raw
    }
}

public struct StreamingContext: Sendable {
    public let runID: UUID
    public let model: String

    public init(runID: UUID, model: String) {
        self.runID = runID
        self.model = model
    }
}

public protocol ProviderAdapter: Sendable {
    func canHandle(request: HTTPRequest) -> Bool
    func parseRequest(_ request: HTTPRequest) throws -> ParsedRequest
    func parseResponse(_ response: HTTPResponse, for request: ParsedRequest) throws -> ParsedResponse
    func parseStreamingEvent(_ line: String, context: StreamingContext) throws -> TraceEvent?
}
```

- [ ] **Step 13: Create TokenEstimator/ModelRegistry.swift**

```swift
public struct ModelEntry: Sendable {
    public let id: String
    public let contextLimit: Int
    public let inputPricePer1KTokens: Double
    public let outputPricePer1KTokens: Double

    public init(id: String, contextLimit: Int, inputPricePer1KTokens: Double, outputPricePer1KTokens: Double) {
        self.id = id
        self.contextLimit = contextLimit
        self.inputPricePer1KTokens = inputPricePer1KTokens
        self.outputPricePer1KTokens = outputPricePer1KTokens
    }
}

public struct ModelRegistry: Sendable {
    private let models: [String: ModelEntry]

    public init() {
        // Pricing is approximate and versioned; labeled as estimated in the UI
        self.models = [
            "gpt-4o": ModelEntry(id: "gpt-4o", contextLimit: 128_000, inputPricePer1KTokens: 0.0025, outputPricePer1KTokens: 0.010),
            "gpt-4o-mini": ModelEntry(id: "gpt-4o-mini", contextLimit: 128_000, inputPricePer1KTokens: 0.00015, outputPricePer1KTokens: 0.0006),
        ]
    }

    public func entry(for modelID: String) -> ModelEntry? {
        models[modelID] ?? models.first(where: { modelID.hasPrefix($0.key) })?.value
    }
}
```

- [ ] **Step 14: Create TokenEstimator/TokenEstimator.swift**

```swift
import os.log

public actor TokenEstimator: TokenCounting {
    private let registry: ModelRegistry
    private let logger = Logger(subsystem: "com.contextscope.core", category: "TokenEstimator")

    public init(registry: ModelRegistry = ModelRegistry()) {
        self.registry = registry
    }

    // Conservative heuristic (~4 chars per token). Labeled as estimated in the UI.
    public nonisolated func countTokens(in text: String, model: String) -> Int {
        max(1, text.unicodeScalars.count / 4)
    }

    public nonisolated func isExact(for model: String) -> Bool { false }
}
```

- [ ] **Step 15: Create a placeholder test file**

```swift
// Tests/ContextScopeCoreTests/ContextScopeCoreTests.swift
import XCTest
@testable import ContextScopeCore

final class ContextScopeCoreTests: XCTestCase {
    func testContextItemCreation() {
        let item = ContextItem(category: .systemPrompt, tokenCount: 100, estimatedTokenCount: false, content: "You are a helpful assistant.")
        XCTAssertEqual(item.category, .systemPrompt)
        XCTAssertEqual(item.tokenCount, 100)
    }

    func testContextSnapshotPressure() {
        let item = ContextItem(category: .conversationHistory, tokenCount: 1000, estimatedTokenCount: true, content: "history")
        let snap = ContextSnapshot(runID: UUID(), items: [item], totalTokens: 1000, contextLimit: 4000)
        XCTAssertEqual(snap.pressurePercent, 25.0, accuracy: 0.01)
    }

    func testTokenEstimatorHeuristic() {
        let estimator = TokenEstimator()
        let count = estimator.countTokens(in: "Hello, world!", model: "gpt-4o")
        XCTAssertGreaterThan(count, 0)
    }
}
```

- [ ] **Step 16: Commit**

```bash
git add Packages/ContextScopeCore/
git commit -m "feat: add ContextScopeCore package — models, protocols, token estimator stubs"
```

---

### Task 4: Remaining Swift Packages

**Files:** Package.swift + source stubs for Capture, Storage, Visualization, DemoData

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p Packages/ContextScopeCapture/Sources/ContextScopeCapture/Adapters
mkdir -p Packages/ContextScopeCapture/Tests/ContextScopeCaptureTests
mkdir -p Packages/ContextScopeStorage/Sources/ContextScopeStorage/Repositories
mkdir -p Packages/ContextScopeStorage/Sources/ContextScopeStorage/Export
mkdir -p Packages/ContextScopeStorage/Tests/ContextScopeStorageTests
mkdir -p Packages/ContextScopeVisualization/Sources/ContextScopeVisualization/ContextRiver
mkdir -p Packages/ContextScopeVisualization/Sources/ContextScopeVisualization/ExecutionGraph
mkdir -p Packages/ContextScopeVisualization/Sources/ContextScopeVisualization/TimelineReplay
mkdir -p Packages/ContextScopeDemoData/Sources/ContextScopeDemoData/Fixtures
mkdir -p Packages/ContextScopeDemoData/Tests/ContextScopeDemoDataTests
```

- [ ] **Step 2: Create Packages/ContextScopeCapture/Package.swift**

```swift
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
```

- [ ] **Step 3: Create Capture source stubs**

`ProxyServer.swift`:
```swift
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
```

`RequestInterceptor.swift`:
```swift
import Foundation
import ContextScopeCore

public actor RequestInterceptor {
    private let adapters: AdapterRegistry
    private let classifier: ContextClassifier

    public init(adapters: AdapterRegistry, classifier: ContextClassifier) {
        self.adapters = adapters
        self.classifier = classifier
    }

    public func intercept(request: HTTPRequest) async throws -> ParsedRequest {
        fatalError("unimplemented")
    }
}
```

`UpstreamForwarder.swift`:
```swift
import Foundation
import ContextScopeCore

public actor UpstreamForwarder {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func forward(request: HTTPRequest, to baseURL: URL) async throws -> HTTPResponse {
        fatalError("unimplemented")
    }
}
```

`StreamingParser.swift`:
```swift
import Foundation
import ContextScopeCore

public struct StreamingParser: Sendable {
    public init() {}

    public func parse(sseLines: AsyncLineSequence<URL.AsyncBytes>, context: StreamingContext, adapter: any ProviderAdapter) -> AsyncStream<TraceEvent> {
        fatalError("unimplemented")
    }
}
```

`Sanitizer.swift`:
```swift
import Foundation

// Redacts secrets from headers and body before any logging, storage, or export.
public struct Sanitizer: Sendable {
    static let redactedPatterns: [String] = [
        "Authorization",
        "x-api-key",
        "api-key",
        "cookie",
        "set-cookie",
    ]

    public init() {}

    public func sanitize(headers: [String: String]) -> [String: String] {
        headers.mapValues { value in
            // TODO: implement pattern matching redaction
            _ = value
            return "[REDACTED]"
        }.filter { key, _ in
            Self.redactedPatterns.contains(where: { key.caseInsensitiveCompare($0) == .orderedSame })
        }
    }
}
```

`ContextClassifier.swift`:
```swift
import Foundation
import ContextScopeCore

public struct ContextClassifier: Sendable {
    public init() {}

    public func classify(message: [String: Any]) -> ContextCategory {
        fatalError("unimplemented")
    }
}
```

`Adapters/AdapterRegistry.swift`:
```swift
import ContextScopeCore

public struct AdapterRegistry: Sendable {
    private let adapters: [any ProviderAdapter]

    public init(adapters: [any ProviderAdapter] = []) {
        self.adapters = adapters
    }

    public func adapter(for request: HTTPRequest) -> (any ProviderAdapter)? {
        adapters.first { $0.canHandle(request: request) }
    }
}
```

- [ ] **Step 4: Create Packages/ContextScopeStorage/Package.swift**

```swift
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
```

- [ ] **Step 5: Create Storage source stubs**

`Database.swift`:
```swift
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
```

`Repositories/RunRepository.swift`:
```swift
import Foundation
import ContextScopeCore

public actor RunRepository {
    private let database: Database

    public init(database: Database) {
        self.database = database
    }

    public func save(_ run: Run) async throws {
        fatalError("unimplemented")
    }

    public func fetch(for sessionID: UUID) async throws -> [Run] {
        fatalError("unimplemented")
    }

    public func delete(id: UUID) async throws {
        fatalError("unimplemented")
    }
}
```

`Repositories/SessionRepository.swift`:
```swift
import Foundation
import ContextScopeCore

public actor SessionRepository {
    private let database: Database

    public init(database: Database) {
        self.database = database
    }

    public func save(_ session: Session) async throws {
        fatalError("unimplemented")
    }

    public func fetch(for projectID: UUID) async throws -> [Session] {
        fatalError("unimplemented")
    }

    public func delete(id: UUID) async throws {
        fatalError("unimplemented")
    }
}
```

`Export/TraceExporter.swift`:
```swift
import Foundation
import ContextScopeCore

public struct TraceExporter: Sendable {
    public init() {}

    public func export(run: Run, events: [TraceEvent]) throws -> Data {
        fatalError("unimplemented")
    }

    public func `import`(from data: Data) throws -> (Run, [TraceEvent]) {
        fatalError("unimplemented")
    }
}
```

- [ ] **Step 6: Create Packages/ContextScopeVisualization/Package.swift**

```swift
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
```

- [ ] **Step 7: Create Visualization source stubs**

`ContextRiver/CategoryStyle.swift`:
```swift
import SwiftUI
import ContextScopeCore

public struct CategoryStyle: Sendable {
    public let color: Color
    public let label: String

    public static let styles: [ContextCategory: CategoryStyle] = [
        .systemPrompt: CategoryStyle(color: .blue, label: "System Prompt"),
        .conversationHistory: CategoryStyle(color: .green, label: "History"),
        .toolDefinitions: CategoryStyle(color: .orange, label: "Tool Definitions"),
        .retrievedContext: CategoryStyle(color: .purple, label: "Retrieved Context"),
        .toolOutputs: CategoryStyle(color: .yellow, label: "Tool Outputs"),
        .other: CategoryStyle(color: .gray, label: "Other"),
    ]

    public init(color: Color, label: String) {
        self.color = color
        self.label = label
    }
}
```

`ContextRiver/RiverLayout.swift`:
```swift
import Foundation
import ContextScopeCore

public struct RiverLane: Identifiable, Sendable {
    public let id: ContextCategory
    public let proportion: Double

    public init(id: ContextCategory, proportion: Double) {
        self.id = id
        self.proportion = proportion
    }
}

public struct RiverLayout: Sendable {
    public static func lanes(from snapshot: ContextSnapshot) -> [RiverLane] {
        fatalError("unimplemented")
    }
}
```

`ContextRiver/RiverLegendView.swift`:
```swift
import SwiftUI
import ContextScopeCore

public struct RiverLegendView: View {
    public let snapshot: ContextSnapshot

    public init(snapshot: ContextSnapshot) {
        self.snapshot = snapshot
    }

    public var body: some View {
        fatalError("unimplemented")
    }
}
```

`ExecutionGraph/GraphLayout.swift`:
```swift
import Foundation
import ContextScopeCore

public struct GraphNode: Identifiable, Sendable {
    public let id: UUID
    public let event: TraceEvent

    public init(id: UUID = UUID(), event: TraceEvent) {
        self.id = id
        self.event = event
    }
}

public struct GraphLayout: Sendable {
    public static func layout(events: [TraceEvent]) -> [GraphNode] {
        fatalError("unimplemented")
    }
}
```

`TimelineReplay/ReplayEngine.swift`:
```swift
import Foundation
import ContextScopeCore

@MainActor
public final class ReplayEngine: ObservableObject {
    @Published public private(set) var currentSnapshot: ContextSnapshot?
    @Published public private(set) var currentFrameIndex: Int = 0

    private let frames: [ContextSnapshot]

    public init(frames: [ContextSnapshot]) {
        self.frames = frames
    }

    public func seek(to index: Int) {
        fatalError("unimplemented")
    }

    public func play() async {
        fatalError("unimplemented")
    }
}
```

- [ ] **Step 8: Create Packages/ContextScopeDemoData/Package.swift**

```swift
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
```

- [ ] **Step 9: Create DemoData source stubs and fixtures**

`DemoSession.swift`:
```swift
import Foundation
import ContextScopeCore

public struct DemoScenario: Identifiable, Sendable {
    public let id: String
    public let displayName: String
    public let description: String
    public let fixtureFilename: String

    public init(id: String, displayName: String, description: String, fixtureFilename: String) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.fixtureFilename = fixtureFilename
    }
}

public struct DemoSession: Sendable {
    public let scenario: DemoScenario
    public let frames: [ContextSnapshot]

    public init(scenario: DemoScenario, frames: [ContextSnapshot]) {
        self.scenario = scenario
        self.frames = frames
    }
}
```

`DemoScenarioRegistry.swift`:
```swift
import Foundation

public enum DemoScenarioRegistry {
    public static let all: [DemoScenario] = [
        DemoScenario(
            id: "healthy_request",
            displayName: "Healthy Request",
            description: "Moderate context, one tool call, low pressure.",
            fixtureFilename: "healthy_request.contextscope.json"
        ),
        DemoScenario(
            id: "bloated_context",
            displayName: "Bloated Context",
            description: "Oversized tool definitions, duplicate history, >85% context pressure.",
            fixtureFilename: "bloated_context.contextscope.json"
        ),
        DemoScenario(
            id: "runaway_tool_loop",
            displayName: "Runaway Tool Loop",
            description: "Repeated tool calls, growing results, increasing latency, final failure.",
            fixtureFilename: "runaway_tool_loop.contextscope.json"
        ),
    ]

    public static func load(scenario: DemoScenario) throws -> DemoSession {
        fatalError("unimplemented")
    }
}
```

`Fixtures/healthy_request.contextscope.json`:
```json
{
  "version": "0.1",
  "scenario": "healthy_request",
  "frames": [
    {
      "timestamp": "2024-01-01T00:00:00Z",
      "totalTokens": 512,
      "contextLimit": 128000,
      "items": [
        {"category": "system_prompt", "tokenCount": 128, "estimatedTokenCount": false, "content": "[demo system prompt]"},
        {"category": "conversation_history", "tokenCount": 256, "estimatedTokenCount": false, "content": "[demo history]"},
        {"category": "tool_definitions", "tokenCount": 128, "estimatedTokenCount": false, "content": "[demo tools]"}
      ]
    }
  ]
}
```

`Fixtures/bloated_context.contextscope.json`:
```json
{
  "version": "0.1",
  "scenario": "bloated_context",
  "frames": [
    {
      "timestamp": "2024-01-01T00:00:00Z",
      "totalTokens": 109000,
      "contextLimit": 128000,
      "items": [
        {"category": "system_prompt", "tokenCount": 512, "estimatedTokenCount": false, "content": "[demo system prompt]"},
        {"category": "conversation_history", "tokenCount": 45000, "estimatedTokenCount": false, "content": "[demo history with duplicates]"},
        {"category": "tool_definitions", "tokenCount": 52000, "estimatedTokenCount": false, "content": "[bloated tool definitions]"},
        {"category": "retrieved_context", "tokenCount": 11488, "estimatedTokenCount": false, "content": "[retrieved docs]"}
      ]
    }
  ]
}
```

`Fixtures/runaway_tool_loop.contextscope.json`:
```json
{
  "version": "0.1",
  "scenario": "runaway_tool_loop",
  "frames": [
    {
      "timestamp": "2024-01-01T00:00:00Z",
      "totalTokens": 2048,
      "contextLimit": 128000,
      "items": [
        {"category": "system_prompt", "tokenCount": 256, "estimatedTokenCount": false, "content": "[demo system prompt]"},
        {"category": "tool_outputs", "tokenCount": 1792, "estimatedTokenCount": false, "content": "[first tool result]"}
      ]
    },
    {
      "timestamp": "2024-01-01T00:00:05Z",
      "totalTokens": 8192,
      "contextLimit": 128000,
      "items": [
        {"category": "system_prompt", "tokenCount": 256, "estimatedTokenCount": false, "content": "[demo system prompt]"},
        {"category": "tool_outputs", "tokenCount": 7936, "estimatedTokenCount": false, "content": "[accumulated tool results]"}
      ]
    }
  ]
}
```

- [ ] **Step 10: Commit**

```bash
git add Packages/ContextScopeCapture/ Packages/ContextScopeStorage/ Packages/ContextScopeVisualization/ Packages/ContextScopeDemoData/
git commit -m "feat: add Capture, Storage, Visualization, and DemoData package stubs"
```

---

### Task 5: Developer Scripts

**Files:** `Scripts/bootstrap.sh`, `Scripts/test.sh`, `Scripts/run-demo.sh`

- [ ] **Step 1: Create Scripts/bootstrap.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "==> ContextScope bootstrap"
echo ""

# Verify requirements
if ! command -v swift &>/dev/null; then
  echo "Error: swift not found. Install Xcode 15 or later." >&2
  exit 1
fi

SWIFT_VERSION=$(swift --version 2>&1 | head -1)
echo "Swift: $SWIFT_VERSION"

MACOS_VERSION=$(sw_vers -productVersion)
echo "macOS: $MACOS_VERSION"

echo ""
echo "==> Resolving Swift Package Manager dependencies"

for pkg in ContextScopeCore ContextScopeCapture ContextScopeStorage ContextScopeDemoData; do
  echo "  Resolving Packages/$pkg..."
  swift package resolve --package-path "Packages/$pkg" 2>&1 | tail -1
done

echo ""
echo "==> Building packages"

for pkg in ContextScopeCore ContextScopeCapture ContextScopeStorage ContextScopeDemoData; do
  echo "  Building Packages/$pkg..."
  swift build --package-path "Packages/$pkg" -q
done

echo ""
echo "Bootstrap complete."
echo ""
echo "Next steps:"
echo "  1. Open the app in Xcode:"
echo "       open App/ContextScopeApp/ContextScopeApp.xcworkspace"
echo "  2. Build and run the ContextScopeApp scheme."
echo "  3. To run tests: ./Scripts/test.sh"
echo "  4. To run Demo Mode without an API key: ./Scripts/run-demo.sh"
```

- [ ] **Step 2: Create Scripts/test.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "==> ContextScope test suite"
echo ""

FAILED=0

for pkg in ContextScopeCore ContextScopeCapture ContextScopeStorage ContextScopeDemoData; do
  echo "--- $pkg ---"
  if swift test --package-path "Packages/$pkg"; then
    echo "PASS: $pkg"
  else
    echo "FAIL: $pkg" >&2
    FAILED=$((FAILED + 1))
  fi
  echo ""
done

echo "Note: ContextScopeVisualization uses SwiftUI — test it from Xcode."
echo ""

if [ "$FAILED" -gt 0 ]; then
  echo "FAILED: $FAILED package(s) had test failures." >&2
  exit 1
else
  echo "All tests passed."
fi
```

- [ ] **Step 3: Create Scripts/run-demo.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "==> ContextScope Demo Mode"
echo ""
echo "Demo Mode replays prerecorded sessions — no API key required."
echo ""
echo "To run Demo Mode:"
echo "  1. Open the app: open App/ContextScopeApp/ContextScopeApp.xcworkspace"
echo "  2. Build and run the ContextScopeApp scheme in Xcode."
echo "  3. Click 'Play Demo' on the welcome screen."
echo "  4. Select a scenario:"
echo "       • Healthy Request    — moderate context, one tool call, low pressure"
echo "       • Bloated Context    — oversized tools, duplicate history, >85% pressure"
echo "       • Runaway Tool Loop  — repeated tool calls, growing results, final failure"
echo ""
echo "Alternatively, load a fixture directly:"
echo "  swift run --package-path Packages/ContextScopeDemoData"
echo ""
echo "Sample trace fixtures are in:"
echo "  Packages/ContextScopeDemoData/Sources/ContextScopeDemoData/Fixtures/"
echo "  Examples/sample-traces/"
```

- [ ] **Step 4: Make scripts executable and commit**

```bash
chmod +x Scripts/bootstrap.sh Scripts/test.sh Scripts/run-demo.sh
git add Scripts/
git commit -m "chore: add bootstrap, test, and run-demo scripts"
```

---

### Task 6: Documentation

**Files:** `Docs/TraceFormat.md`, `Docs/StarterIssues.md`, `Docs/DemoRecordingGuide.md`, 3 ADRs

- [ ] **Step 1: Create Docs/TraceFormat.md**

```markdown
# ContextScope Trace Format

Version: **0.1** (pre-release — subject to change)

Trace files use the extension `.contextscope.json`. They are JSON documents with the following top-level structure.

---

## Top-level object

| Field | Type | Required | Description |
|---|---|---|---|
| `version` | string | yes | Schema version. Currently `"0.1"`. |
| `scenario` | string | no | Human-readable identifier for demo/test traces. |
| `session` | Session | no | Session metadata. |
| `frames` | Frame[] | yes | Ordered list of context snapshots. At least one required. |

---

## Session object

| Field | Type | Required | Description |
|---|---|---|---|
| `id` | UUID string | yes | Unique identifier. |
| `startedAt` | ISO 8601 datetime | yes | When the session began. |
| `endedAt` | ISO 8601 datetime | no | When the session ended. Absent for in-progress sessions. |

---

## Frame object

A frame is a snapshot of the context window at a point in time.

| Field | Type | Required | Description |
|---|---|---|---|
| `timestamp` | ISO 8601 datetime | yes | When this snapshot was captured. |
| `totalTokens` | integer | yes | Sum of all item token counts. |
| `contextLimit` | integer | no | Model context limit if known. Used to compute pressure %. |
| `items` | ContextItem[] | yes | Ordered list of context items. At least one required. |

---

## ContextItem object

| Field | Type | Required | Description |
|---|---|---|---|
| `category` | string (enum) | yes | See categories below. |
| `tokenCount` | integer | yes | Token count for this item. |
| `estimatedTokenCount` | boolean | yes | `true` if tokenCount is a heuristic estimate. |
| `content` | string | yes | The raw text content. Secrets must be redacted before export. |

### Category values

| Value | Description |
|---|---|
| `system_prompt` | The system-level instruction. |
| `conversation_history` | Prior turns (user + assistant messages). |
| `tool_definitions` | Function/tool schema sent to the model. |
| `retrieved_context` | RAG chunks or injected retrieved content. |
| `tool_outputs` | Results from tool calls. |
| `other` | Anything not covered by the above categories. |

---

## Secret redaction

Content in `.contextscope.json` exports must have all secrets redacted. The following patterns are replaced with `[REDACTED]` by `Sanitizer` before writing:

- `Authorization: Bearer ...`
- `x-api-key: ...`
- `api-key: ...`
- Cookie values
- Any value matching `sk-...` or `sess-...` patterns

Do not include real API keys or user credentials in fixture files.

---

## Versioning

The `version` field follows semver. Breaking schema changes increment the major version. Additive changes increment the minor version. Importers must reject traces with an unsupported major version and warn on unsupported minor versions.

---

## Example

See `Examples/sample-traces/` and `Packages/ContextScopeDemoData/Sources/ContextScopeDemoData/Fixtures/` for working examples.
```

- [ ] **Step 2: Create Docs/StarterIssues.md**

```markdown
# Starter Issues

Good first contributions for new ContextScope contributors. Each item is self-contained, well-defined, and doesn't require deep knowledge of the full codebase.

Issues are also labeled [`good first issue`](https://github.com/ashutosh160798/context-scope/labels/good%20first%20issue) on GitHub.

---

## Documentation

- [ ] **Add missing XML comments to all `public` types in `ContextScopeCore`** — open the package, add `/// One-sentence description.` to each `public struct`, `enum`, and `protocol`. No logic changes needed.

- [ ] **Proofread and fix CONTRIBUTING.md** — test the setup steps on a clean macOS Sonoma install and fix any steps that don't work.

---

## Tests

- [ ] **Add unit tests for `ModelRegistry`** — `ContextScopeCore/Tests/ContextScopeCoreTests/`. Test prefix matching (e.g., `"gpt-4o-2024-11-20"` should resolve to the `"gpt-4o"` entry). Use `XCTest`.

- [ ] **Add unit tests for `ContextSnapshot.pressurePercent`** — test `nil` when `contextLimit` is nil, `nil` when `contextLimit` is zero, and correct values at 25%, 85%, and 100%.

- [ ] **Add unit tests for `Sanitizer.sanitize(headers:)`** — once `Sanitizer` is implemented, add tests proving that `Authorization`, `x-api-key`, and `cookie` headers are redacted and that `Content-Type` is preserved.

---

## Trace Fixtures

- [ ] **Add a third demo fixture: Multi-turn conversation** — create `Packages/ContextScopeDemoData/Sources/ContextScopeDemoData/Fixtures/multi_turn.contextscope.json` following the schema in `Docs/TraceFormat.md`. Use only fictional content.

- [ ] **Validate existing fixtures against TraceFormat.md** — write a Swift test that decodes all three fixture files and asserts the required fields are present.

---

## Tooling

- [ ] **Add a `validate-traces.sh` script** — in `Scripts/`, write a Bash script that checks every `*.contextscope.json` under `Packages/` and `Examples/` for required fields (`version`, `frames`, at least one item per frame). Exit non-zero if any file fails.

- [ ] **Pin the Xcode version in CI** — update `.github/workflows/ci.yml` to use the latest stable Xcode 15.x release and document the choice.

---

## Examples

- [ ] **Add a Python example with streaming** — in `Examples/python/streaming_chat.py`, show how to consume SSE chunks from the proxy using the `openai` SDK with `stream=True`.

- [ ] **Add a Node.js example with streaming** — in `Examples/nodejs/streaming_chat.js`, show the same using the `openai` npm package with `stream: true`.
```

- [ ] **Step 3: Create Docs/DemoRecordingGuide.md**

```markdown
# Demo Recording Guide

This guide explains how to capture a compelling 30-second screen recording of ContextScope's Context Pressure River animation for use in README screenshots, the project website, and launch posts.

---

## Prerequisites

- ContextScope built and running locally (see `CONTRIBUTING.md` → Development Setup)
- macOS Screen Recording permission granted to QuickTime Player or your capture tool
- Display resolution: 2560×1600 or 1920×1200 recommended for crisp screenshots

---

## Setup (do once)

1. Build and launch the app: `open App/ContextScopeApp/ContextScopeApp.xcworkspace` → Run
2. Click **Play Demo** on the welcome screen
3. Select the **Bloated Context** scenario — it produces the most visually striking river with high pressure warnings

---

## Recording the Context Pressure River (30-second clip)

1. Open QuickTime Player → File → New Screen Recording
2. Select the ContextScope window only (not full screen)
3. Start recording
4. On the welcome screen, click **Play Demo** → **Bloated Context**
5. Watch the river animate for ~25 seconds — the pressure warnings should fire automatically
6. Stop recording

**What to capture:**
- The river filling from left as context items stream in
- Color-coded lanes (blue = system prompt, orange = tool definitions dominating)
- The yellow (85%) and red (95%) pressure threshold lines activating
- The warning badge appearing in the sidebar

---

## Capturing a Static Screenshot

For the README hero image:

1. Pause Demo Mode at the moment of peak pressure (when the red 95% line activates)
2. Press `⌘⇧4` then `Space` to capture the window
3. Save to `Docs/screenshots/context-river-peak-pressure.png`

---

## Post-processing

- Trim the clip to ≤30 seconds
- Convert to GIF with `ffmpeg` for inline README use:

```bash
ffmpeg -i demo.mov -vf "fps=12,scale=1200:-1:flags=lanczos" -loop 0 demo.gif
```

- Aim for <3 MB GIF for fast loading on GitHub

---

## Checklist before publishing

- [ ] No real API keys or credentials visible in any frame
- [ ] No real user data visible — Demo Mode uses only fictional content
- [ ] No third-party copyrighted content in any visible text
```

- [ ] **Step 4: Create Docs/ArchitectureDecisions/ADR-001-embedded-http-server.md**

```markdown
# ADR-001: Embedded HTTP Server Selection

**Status:** Proposed  
**Date:** 2024-01-01

---

## Context

ContextScope needs a local HTTP server on `127.0.0.1:4319` to act as an OpenAI-compatible proxy. The server must:

- Accept HTTP/1.1 connections (OpenAI SDKs do not require HTTP/2)
- Support chunked transfer encoding for SSE streaming
- Start and stop cleanly from a macOS app
- Have no external service dependencies
- Work entirely on-device

Candidates considered:

1. **SwiftNIO** — Apple-maintained async network framework, no binaries, pure Swift
2. **Vapor** — web framework built on SwiftNIO, opinionated
3. **GCDHTTPServer** — Objective-C, last updated 2020
4. **Foundation URLSession + CFSocket** — low-level, verbose
5. **Network.framework** — Apple-native but no built-in HTTP layer

---

## Decision

**TBD** — to be decided when the `ContextScopeCapture` package is implemented.

Leading candidate: **SwiftNIO** directly (without Vapor) for minimal footprint and direct control over SSE streaming. Vapor adds routing and middleware that ContextScope does not need; it would also add ~50 transitive dependencies.

---

## Consequences

- If SwiftNIO: `ContextScopeCapture` gains a dependency on `swift-nio`. Core and other packages remain dependency-free.
- The `ProxyServer` actor wraps the NIO channel lifecycle. Start/stop is fully async.
- SSE streaming requires custom channel handlers; `StreamingParser.swift` owns this.
```

- [ ] **Step 5: Create Docs/ArchitectureDecisions/ADR-002-sqlite-approach.md**

```markdown
# ADR-002: SQLite Persistence Approach

**Status:** Proposed  
**Date:** 2024-01-01

---

## Context

ContextScope stores runs, sessions, context snapshots, and trace events locally in SQLite. Requirements:

- No external server
- Works on macOS Sonoma
- Supports async access from Swift concurrency actors
- Schema migrations for future format evolution

Candidates considered:

1. **GRDB.swift** — popular Swift SQLite wrapper, async-compatible, migration support
2. **SQLite.swift** — type-safe query builder, fewer abstractions than GRDB
3. **Core Data with SQLite store** — familiar but heavyweight for this use case
4. **Raw `sqlite3` C API** — full control, no dependencies, verbose

---

## Decision

**TBD** — to be decided when the `ContextScopeStorage` package is implemented.

Leading candidate: **GRDB.swift** for its migration DSL and async compatibility. If keeping zero external dependencies is prioritized, raw `sqlite3` via `Database.swift` (with a hand-rolled migration runner) is the fallback.

---

## Consequences

- If GRDB: `ContextScopeStorage` gains one external dependency. All other packages remain dependency-free.
- Schema is versioned in `Database.swift`. Each migration is a numbered SQL string applied in order.
- The `actor` isolation model in `RunRepository` and `SessionRepository` prevents concurrent write conflicts.
- File permissions for the SQLite database file must be `0600` to prevent other OS users from reading captured prompts.
```

- [ ] **Step 6: Create Docs/ArchitectureDecisions/ADR-003-animation-model.md**

```markdown
# ADR-003: Context Pressure River Animation Model

**Status:** Proposed  
**Date:** 2024-01-01

---

## Context

The Context Pressure River is the primary visual feature: an animated, proportional bar that fills in real-time as context items arrive, segmented by category, with pressure threshold overlays.

Requirements:

- Runs at 60 fps on a 2021+ MacBook Pro
- Animates incrementally as `TraceEvent` objects arrive (streaming)
- Supports scrubbing (Timeline Replay) with frame-accurate redraw
- No third-party animation libraries

Candidates considered:

1. **SwiftUI Canvas + `TimelineView`** — declarative, integrates naturally with `@Observable`
2. **SwiftUI `Rectangle` / `GeometryReader` layout** — declarative, simpler, lower performance ceiling
3. **AppKit `NSView` with Core Animation layers** — maximum control and performance
4. **Metal shader** — unnecessary complexity for a bar chart animation

---

## Decision

**TBD** — to be decided when the `ContextScopeVisualization` package is implemented.

Leading candidate: **SwiftUI Canvas** within a `TimelineView` for streaming updates, falling back to `Canvas` with explicit `setNeedsDisplay` calls for scrubbing. This keeps the full visualization layer in SwiftUI and avoids AppKit bridging.

---

## Consequences

- `ContextScopeVisualization` is a SwiftUI-only package. It cannot be tested on Linux CI runners.
- `RiverLayout.swift` must be pure Swift (no SwiftUI) so layout logic can be unit tested.
- `CategoryStyle.swift` is SwiftUI-dependent (uses `Color`). Anything referencing colors cannot run in CI.
- The `ReplayEngine` is `@MainActor` and publishes frames via `@Published` properties for SwiftUI binding.
```

- [ ] **Step 7: Commit**

```bash
git add Docs/
git commit -m "docs: add TraceFormat, StarterIssues, DemoRecordingGuide, and ADR stubs"
```

---

### Task 7: Examples

**Files:** `Examples/python/basic_chat.py`, `Examples/nodejs/basic_chat.js`, `Examples/curl/basic_chat.sh`, `Examples/sample-traces/README.md`

- [ ] **Step 1: Create Examples/python/basic_chat.py**

```python
"""
ContextScope — Python example
Routes OpenAI SDK traffic through the local ContextScope proxy.
"""

from openai import OpenAI

# Point the SDK at the local proxy — no other code changes needed
client = OpenAI(
    base_url="http://127.0.0.1:4319/v1",
    api_key="your-upstream-api-key",  # Your real key — forwarded to the provider
)

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "What is the capital of France?"},
    ],
)

print(response.choices[0].message.content)
print(f"\nTokens used: {response.usage.total_tokens}")
```

- [ ] **Step 2: Create Examples/nodejs/basic_chat.js**

```javascript
// ContextScope — Node.js example
// Routes OpenAI SDK traffic through the local ContextScope proxy.

import OpenAI from 'openai';

// Point the SDK at the local proxy — no other code changes needed
const client = new OpenAI({
  baseURL: 'http://127.0.0.1:4319/v1',
  apiKey: 'your-upstream-api-key', // Your real key — forwarded to the provider
});

const response = await client.chat.completions.create({
  model: 'gpt-4o',
  messages: [
    { role: 'system', content: 'You are a helpful assistant.' },
    { role: 'user', content: 'What is the capital of France?' },
  ],
});

console.log(response.choices[0].message.content);
console.log(`\nTokens used: ${response.usage.total_tokens}`);
```

- [ ] **Step 3: Create Examples/curl/basic_chat.sh**

```bash
#!/usr/bin/env bash
# ContextScope — curl example
# Routes a raw HTTP request through the local ContextScope proxy.

curl http://127.0.0.1:4319/v1/chat/completions \
  -s \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-upstream-api-key" \
  -d '{
    "model": "gpt-4o",
    "messages": [
      {"role": "system", "content": "You are a helpful assistant."},
      {"role": "user", "content": "What is the capital of France?"}
    ]
  }' | python3 -m json.tool
```

- [ ] **Step 4: Create Examples/sample-traces/README.md**

```markdown
# Sample Traces

These `.contextscope.json` files are example traces that can be loaded into ContextScope for testing and development.

| File | Scenario | Description |
|---|---|---|
| See `Packages/ContextScopeDemoData/Sources/ContextScopeDemoData/Fixtures/` | All demo scenarios | The three built-in Demo Mode fixtures |

## Creating your own trace

1. Start the ContextScope proxy
2. Route traffic through `http://127.0.0.1:4319/v1`
3. Complete a session
4. In ContextScope, choose File → Export Trace

Or create one manually following [`Docs/TraceFormat.md`](../../Docs/TraceFormat.md).

## Validating a trace

```bash
./Scripts/validate-traces.sh path/to/trace.contextscope.json
```

(Script coming in a starter issue — see `Docs/StarterIssues.md`.)
```

- [ ] **Step 5: Commit**

```bash
git add Examples/
git commit -m "docs: add Python, Node.js, and curl examples plus sample-traces README"
```

---

### Task 8: Push to GitHub

- [ ] **Step 1: Verify working tree is clean**

```bash
git status
```

Expected: `nothing to commit, working tree clean`

- [ ] **Step 2: Push all commits**

```bash
git push origin main
```

- [ ] **Step 3: Verify on GitHub**

Open `https://github.com/ashutosh160798/context-scope` and confirm all directories appear in the file tree.

---

## Self-Review

**Spec coverage:**
- [x] CODE_OF_CONDUCT.md → Task 1
- [x] SECURITY.md → Task 1
- [x] ROADMAP.md → Task 1
- [x] .github/ issue templates → Task 2
- [x] .github/ PR template → Task 2
- [x] .github/ CI workflow → Task 2
- [x] Package.swift for all 5 packages → Tasks 3 & 4
- [x] Stub Swift source files → Tasks 3 & 4
- [x] Scripts/bootstrap.sh → Task 5
- [x] Scripts/test.sh → Task 5
- [x] Scripts/run-demo.sh → Task 5
- [x] Docs/TraceFormat.md → Task 6
- [x] Docs/StarterIssues.md → Task 6
- [x] Docs/DemoRecordingGuide.md → Task 6
- [x] Docs/ArchitectureDecisions/ ADR stubs → Task 6
- [x] Examples/ Python, Node.js, curl → Task 7
- [x] Examples/ sample traces → Task 7 (README; fixtures in DemoData package)

**Gaps found:** None. All items from the spec are covered.

**Placeholder scan:** No "TBD" or "TODO" outside of intentional `fatalError("unimplemented")` in stub bodies (which are correct for pre-implementation stubs). ADRs use "TBD" for decisions intentionally not made yet.

**Type consistency:** `ContextCategory`, `ContextItem`, `ContextSnapshot`, `TraceEvent`, `HTTPRequest`, `HTTPResponse`, `ParsedRequest`, `ParsedResponse` are defined in Task 3 and used correctly by name in Tasks 4–7.
