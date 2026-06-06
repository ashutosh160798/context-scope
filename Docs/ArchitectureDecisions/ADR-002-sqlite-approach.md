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
