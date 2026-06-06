# ContextScope — See exactly what your AI sees.

> A local-first macOS debugger for LLM context windows, token usage, tool calls, and agent execution.

ContextScope is Activity Monitor and Time Machine for LLM context. Route your OpenAI-compatible API traffic through a local proxy and watch context build, token budgets fill, tools fire, and agents loop — live, on your Mac, with nothing leaving your machine except the request to your model provider.

---

## What it does

- **Context Pressure River** — animated, proportional visualization of every token entering the context window, segmented by type: system prompt, conversation history, tool definitions, retrieved context, and tool outputs.
- **Live Execution Graph** — causal DAG of model calls, tool calls, and results updating as your agent runs.
- **Timeline Replay** — scrub any completed run frame-by-frame, reconstructing exactly what the model saw at each step.
- **Token accounting** — exact counts from provider usage data when available; clearly labeled estimates otherwise.
- **Context warnings** — fires when context exceeds 70 / 85 / 95%, when a single item exceeds 25%, when tool definitions bloat the input, or when duplicate messages appear.
- **Local proxy** — drop-in OpenAI-compatible endpoint at `http://127.0.0.1:4319/v1`. Point any existing SDK at it.
- **Menu-bar utility** — proxy status, current context %, last latency, and quick actions without opening the main window.
- **Privacy-first** — all captured data stays on your Mac. No accounts, no telemetry, no cloud.

---

## Screenshots

> _Screenshots and demo GIF coming soon. See [Demo Mode](#demo-mode) to run the visualization without an API key._

---

## Feature overview

| Feature | Status |
|---|---|
| OpenAI-compatible proxy (`/v1/chat/completions`) | 🚧 In development |
| Streaming SSE passthrough | 🚧 In development |
| Context Pressure River visualization | 🚧 In development |
| Execution graph | 🚧 In development |
| Timeline replay | 🚧 In development |
| Token accounting (exact + estimated) | 🚧 In development |
| Context warnings | 🚧 In development |
| Menu-bar utility | 🚧 In development |
| Demo Mode (no API key required) | 🚧 In development |
| Local SQLite persistence | 🚧 In development |
| Trace export / import (`.contextscope.json`) | 🚧 In development |
| API key stored in macOS Keychain | 🚧 In development |
| Secret redaction before export | 🚧 In development |

---

## Architecture

```
ContextScope/
├── App/
│   ├── ContextScopeApp/          # Main SwiftUI window application
│   └── ContextScopeMenuBar/      # Menu-bar extra
├── Packages/
│   ├── ContextScopeCore/         # Shared models, protocols, token accounting
│   ├── ContextScopeCapture/      # Local HTTP proxy and upstream forwarding
│   ├── ContextScopeStorage/      # SQLite persistence layer
│   ├── ContextScopeVisualization/# Context Pressure River, execution graph, replay
│   └── ContextScopeDemoData/     # Prerecorded demo sessions and sample traces
├── Tests/                        # Integration and UI tests
├── Examples/                     # Python, Node.js, curl integration examples
├── Scripts/                      # bootstrap.sh, test.sh, run-demo.sh
└── Docs/                         # Architecture decisions, trace format, roadmap
```

Each package has a protocol boundary so the proxy, storage layer, token estimator, and visualization event source can be replaced independently.

See [`Docs/ArchitectureDecisions/`](Docs/ArchitectureDecisions/) for rationale behind major choices (embedded HTTP server selection, SQLite approach, animation model).

---

## Privacy

- All captured prompts, responses, and metadata are stored **only on your Mac** in a local SQLite database.
- API keys are stored in **macOS Keychain**. They are never written to SQLite, logs, exports, or the UI.
- No analytics, no crash reporting SDK, no advertising SDK.
- Capture can be toggled off at any time from the menu bar.
- Individual sessions and all local data can be deleted from the UI.
- Secret patterns (Authorization headers, Bearer tokens, API keys, cookies) are redacted before any export.

---

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 15 or later (for building from source)
- Swift 5.9 or later

No account required. No paid service required. Demo Mode works with no API key.

---

## Installation

### From source (current method — pre-release)

```bash
git clone https://github.com/ashutosh160798/context-scope.git
cd context-scope
./Scripts/bootstrap.sh
open App/ContextScopeApp/ContextScopeApp.xcodeproj
```

Build and run the `ContextScopeApp` scheme in Xcode.

> Signed releases and a Homebrew cask are planned for v0.1.

---

## Demo Mode

No API key needed.

1. Launch ContextScope.
2. Click **Play Demo** on the welcome screen.
3. Select a demo scenario:
   - **Healthy request** — moderate context, one tool call, low pressure.
   - **Bloated context** — oversized tool definitions, duplicate history, >85% context pressure, multiple warnings.
   - **Runaway tool loop** — repeated tool calls, growing results, increasing latency, final failure.

The Context Pressure River animates immediately. No proxy setup required.

---

## Quick start (real traffic)

1. Start the proxy from the menu bar or app.
2. Copy the local base URL: `http://127.0.0.1:4319/v1`
3. Point your app at it:

**Python**
```python
from openai import OpenAI

client = OpenAI(
    base_url="http://127.0.0.1:4319/v1",
    api_key="your-upstream-key"
)
```

**Node.js**
```javascript
import OpenAI from 'openai';

const client = new OpenAI({
  baseURL: 'http://127.0.0.1:4319/v1',
  apiKey: 'your-upstream-key',
});
```

**Environment variable**
```bash
export OPENAI_BASE_URL="http://127.0.0.1:4319/v1"
```

**curl**
```bash
curl http://127.0.0.1:4319/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-upstream-key" \
  -d '{"model":"gpt-4o","messages":[{"role":"user","content":"Hello"}]}'
```

See [`Examples/`](Examples/) for full working samples.

---

## Supported endpoints (v0.1)

| Endpoint | Status |
|---|---|
| `POST /v1/chat/completions` | Full support (streaming + non-streaming) |
| `POST /v1/responses` | Partial — forwarded, limited parsing |
| `GET /health` | Supported |
| All other endpoints | Forwarded as-is; not captured |

---

## Known limitations (v0.1)

- Tokenizer uses a conservative heuristic estimate when provider usage data is absent. Labeled as **Estimated** in the UI.
- `/v1/responses` context parsing is incomplete. Raw request and response are stored; structured visualization is limited.
- No system-wide HTTPS interception — only traffic explicitly pointed at the local proxy is captured.
- Pricing estimates are approximate, versioned, and labeled as estimated. They can be disabled.
- No OpenTelemetry ingestion yet (planned for v0.3).
- No Anthropic-native message format parsing yet (planned for v0.4).

---

## Roadmap

| Version | Focus |
|---|---|
| **0.1** | OpenAI-compatible proxy, live Context Pressure River, execution graph, timeline replay |
| **0.2** | Run comparison, improved tokenizers, side-by-side diff |
| **0.3** | OpenTelemetry ingestion |
| **0.4** | Anthropic-native message format support |
| **0.5** | RAG retrieval visualization |
| **1.0** | Stable plugin and trace schemas |

See [`ROADMAP.md`](ROADMAP.md) for detailed milestone breakdowns.

---

## vs. LangSmith / Langfuse / other observability platforms

ContextScope is a **local context debugger**, not a replacement for production observability services.

| | ContextScope | LangSmith / Langfuse |
|---|---|---|
| Data location | Your Mac only | Cloud / self-hosted |
| Account required | No | Yes |
| Real-time animation | Yes | Dashboard charts |
| Token-level context inspection | Yes | Varies |
| Production alerting | No | Yes |
| Team workspaces | No | Yes |
| OpenTelemetry | Planned (v0.3) | Yes |

Use ContextScope during development to understand what your agent is doing. Use a production observability platform for alerting, team dashboards, and fleet-wide monitoring.

---

## Contributing

We welcome contributions. See [`CONTRIBUTING.md`](CONTRIBUTING.md) for:
- Development setup
- Architecture map
- How to add a provider adapter
- How to add a context category
- Pull-request expectations
- Testing requirements

Good first issues are labeled [`good first issue`](https://github.com/ashutosh160798/context-scope/labels/good%20first%20issue).

---

## Recording a 30-second demo

See [`Docs/DemoRecordingGuide.md`](Docs/DemoRecordingGuide.md) for exact steps to capture a compelling launch demo of the Context Pressure River animation.

---

## License

Apache License 2.0. See [`LICENSE`](LICENSE).

---

## Community

- Issues: [github.com/ashutosh160798/context-scope/issues](https://github.com/ashutosh160798/context-scope/issues)
- Discussions: [github.com/ashutosh160798/context-scope/discussions](https://github.com/ashutosh160798/context-scope/discussions)
