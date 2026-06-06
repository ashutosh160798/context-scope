# Contributing to ContextScope

Thank you for your interest in contributing. ContextScope is an open-source macOS developer tool, and we welcome improvements at every level — from bug fixes and documentation to new provider adapters and visualization features.

---

## Development setup

**Requirements:**
- macOS 14 (Sonoma) or later
- Xcode 15 or later
- Swift 5.9 or later

**Clone and bootstrap:**
```bash
git clone https://github.com/ashutosh160798/context-scope.git
cd context-scope
./Scripts/bootstrap.sh
```

`bootstrap.sh` resolves Swift Package Manager dependencies and verifies the build. Open the workspace in Xcode:

```bash
open App/ContextScopeApp/ContextScopeApp.xcworkspace
```

Run tests:
```bash
./Scripts/test.sh
```

Run Demo Mode without an API key:
```bash
./Scripts/run-demo.sh
```

---

## Architecture map

```
ContextScope/
├── App/
│   ├── ContextScopeApp/          # Main SwiftUI app target
│   │   ├── Views/                # Window, sidebar, workspace, inspector panels
│   │   ├── ViewModels/           # Observable state bridging packages to views
│   │   └── AppDelegate.swift
│   └── ContextScopeMenuBar/      # NSStatusItem extra
│       ├── MenuBarController.swift
│       └── MenuBarView.swift
│
├── Packages/
│   ├── ContextScopeCore/         # Shared models, protocols, token accounting
│   │   ├── Models/               # Project, Session, Run, ContextSnapshot, TraceEvent
│   │   ├── Protocols/            # TokenCounting, EventSource, StorageProvider
│   │   └── TokenEstimator/       # Conservative heuristic + ModelRegistry
│   │
│   ├── ContextScopeCapture/      # Local HTTP proxy and upstream forwarding
│   │   ├── ProxyServer.swift     # Lifecycle (start/stop)
│   │   ├── RequestInterceptor.swift
│   │   ├── UpstreamForwarder.swift
│   │   ├── StreamingParser.swift # SSE → TraceEvent stream
│   │   └── Sanitizer.swift       # Header and secret redaction
│   │
│   ├── ContextScopeStorage/      # SQLite persistence
│   │   ├── Database.swift        # Schema migrations
│   │   ├── Repositories/         # RunRepository, SessionRepository, etc.
│   │   └── Export/               # .contextscope.json encoder/decoder
│   │
│   ├── ContextScopeVisualization/# Animation and graph rendering
│   │   ├── ContextRiver/         # Context Pressure River canvas
│   │   ├── ExecutionGraph/       # DAG layout and node rendering
│   │   └── TimelineReplay/       # Replay engine and scrubber
│   │
│   └── ContextScopeDemoData/     # Prerecorded sessions
│       ├── DemoSession.swift
│       └── Fixtures/             # JSON trace files for A/B/C demo scenarios
│
├── Tests/                        # Integration and UI tests
├── Examples/                     # Python/Node.js/curl usage examples
├── Scripts/                      # Developer scripts
└── Docs/                         # Architecture decisions, trace format schema
```

Each package exposes only `public` protocols and value types. The App layer depends on all packages; packages do not depend on each other except `ContextScopeCore` (which has no app-layer dependency).

---

## Coding conventions

- Swift 5.9 with Swift Concurrency (`async/await`, `actor`).
- `@Observable` (Observation framework) for view-facing state.
- `Sendable` conformance required on all types crossing concurrency boundaries.
- `snake_case` for database column names; `camelCase` everywhere else.
- No `print()` in library code. Use `Logger` (os.log) with a subsystem of `com.contextscope.*`.
- Every `public` type in a `Packages/` target needs a unit test.
- No third-party dependencies in `ContextScopeCore`. Minimize dependencies in all packages.
- All secrets (API keys, tokens, credentials) must never be logged, stored in SQLite, or emitted to the UI. Use `Sanitizer` before storing any headers.

---

## How to add a provider adapter

Provider adapters live in `ContextScopeCapture/Sources/ContextScopeCapture/Adapters/`.

1. Create a new file: `<ProviderName>Adapter.swift`.
2. Conform to the `ProviderAdapter` protocol defined in `ContextScopeCore`.
3. Implement:
   - `canHandle(request:) -> Bool`
   - `parseRequest(_ request: HTTPRequest) throws -> ParsedRequest`
   - `parseResponse(_ response: HTTPResponse, for request: ParsedRequest) throws -> ParsedResponse`
   - `parseStreamingEvent(_ line: String, context: StreamingContext) throws -> TraceEvent?`
4. Register it in `AdapterRegistry.swift`.
5. Add unit tests in `ContextScopeCaptureTests/Adapters/`.
6. Document any provider-specific behavior in `Docs/ArchitectureDecisions/`.

---

## How to add a context category

Context categories are defined in `ContextScopeCore/Sources/ContextScopeCore/Models/ContextItem.swift`.

1. Add a case to the `ContextCategory` enum.
2. Assign a display color in `ContextScopeVisualization/Sources/.../CategoryStyle.swift`.
3. Add a lane definition in `ContextRiver/RiverLayout.swift`.
4. Update the legend in `ContextRiver/RiverLegendView.swift`.
5. Add classifier logic in `ContextScopeCapture/Sources/.../ContextClassifier.swift`.
6. Update the token-breakdown inspector in `App/ContextScopeApp/Views/Inspector/`.
7. Add a test case in `ContextScopeCoreTests/ContextCategoryTests.swift`.

---

## How to create sample traces

Sample trace files live in `Packages/ContextScopeDemoData/Sources/ContextScopeDemoData/Fixtures/`.

Traces use the versioned `.contextscope.json` format documented in [`Docs/TraceFormat.md`](Docs/TraceFormat.md).

To create a new demo scenario:
1. Add a JSON file following the schema in `Docs/TraceFormat.md`.
2. Create a `DemoScenario` entry in `DemoScenarioRegistry.swift`.
3. Use only fictional data — no real API keys, no real user content, no third-party copyrighted text.
4. Verify the trace validates with `./Scripts/validate-traces.sh`.

---

## Pull-request expectations

- One focused change per PR.
- All existing tests must pass.
- New behavior requires new tests.
- No new third-party dependencies without prior discussion in an issue.
- No private package registries.
- No changes to `Sanitizer.swift` without a corresponding test proving the new pattern is redacted.
- Keep commits conventional: `feat:`, `fix:`, `refactor:`, `test:`, `docs:`, `chore:`.

---

## Testing requirements

- Unit tests run via `./Scripts/test.sh` or `swift test` from any package directory.
- Tests must not call real provider APIs. Use the mock upstream in `Tests/MockUpstream/`.
- UI tests use `XCUIApplication` and may be skipped in CI on non-interactive runners — they must pass locally.
- Integration tests that start the proxy bind to port `0` (random available port) to avoid conflicts.

---

## Reporting security issues

See [`SECURITY.md`](SECURITY.md).
