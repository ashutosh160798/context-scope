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

Leading candidate: **SwiftUI Canvas** within a `TimelineView` for streaming updates, falling back to `Canvas` with explicit redraw calls for scrubbing. This keeps the full visualization layer in SwiftUI and avoids AppKit bridging.

---

## Consequences

- `ContextScopeVisualization` is a SwiftUI-only package. It cannot be tested on Linux CI runners.
- `RiverLayout.swift` must be pure Swift (no SwiftUI) so layout logic can be unit tested.
- `CategoryStyle.swift` is SwiftUI-dependent (uses `Color`). Anything referencing colors cannot run in CI.
- The `ReplayEngine` is `@MainActor` and publishes frames via `@Published` properties for SwiftUI binding.
