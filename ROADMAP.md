# ContextScope Roadmap

This roadmap reflects current intent, not a contractual commitment. Priorities may shift based on contributor interest and user feedback.

---

## v0.1 — Proxy + Live Visualization (current target)

**Goal:** A working local proxy that captures OpenAI-compatible traffic and renders a live Context Pressure River.

| Feature | Status |
|---|---|
| OpenAI-compatible proxy (`POST /v1/chat/completions`) | In development |
| Streaming SSE passthrough | In development |
| Context Pressure River (animated, proportional) | In development |
| Live Execution Graph (causal DAG) | In development |
| Token accounting (exact from usage data; heuristic fallback) | In development |
| Context warnings (70 / 85 / 95%, single-item >25%, bloated tools, duplicates) | In development |
| Menu-bar utility (proxy on/off, context %, last latency) | In development |
| Demo Mode (no API key required, three prerecorded scenarios) | In development |
| Local SQLite persistence | In development |
| API key stored in macOS Keychain | In development |
| Secret redaction before export | In development |
| Trace export / import (`.contextscope.json`) | In development |

Good first issues for v0.1: see [StarterIssues.md](Docs/StarterIssues.md).

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
