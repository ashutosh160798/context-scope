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

Leading candidate: **SwiftNIO** directly (without Vapor) for minimal footprint and direct control over SSE streaming. Vapor adds routing and middleware that ContextScope does not need; it would also add many transitive dependencies.

---

## Consequences

- If SwiftNIO: `ContextScopeCapture` gains a dependency on `swift-nio`. Core and other packages remain dependency-free.
- The `ProxyServer` actor wraps the NIO channel lifecycle. Start/stop is fully async.
- SSE streaming requires custom channel handlers; `StreamingParser.swift` owns this.
