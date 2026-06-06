# Starter Issues

Good first contributions for new ContextScope contributors. Each item is self-contained, well-defined, and does not require deep knowledge of the full codebase.

Issues are also labeled [`good first issue`](https://github.com/ashutosh160798/context-scope/labels/good%20first%20issue) on GitHub.

---

## Documentation

- [ ] **Add missing doc comments to all `public` types in `ContextScopeCore`** — open the package, add `/// One-sentence description.` to each `public struct`, `enum`, and `protocol`. No logic changes needed.

- [ ] **Proofread and fix CONTRIBUTING.md** — test the setup steps on a clean macOS Sonoma install and fix any steps that do not work.

---

## Tests

- [ ] **Add unit tests for `ModelRegistry`** — `ContextScopeCore/Tests/ContextScopeCoreTests/`. Test prefix matching (e.g., `"gpt-4o-2024-11-20"` should resolve to the `"gpt-4o"` entry). Use `XCTest`.

- [ ] **Add unit tests for `ContextSnapshot.pressurePercent`** — test `nil` when `contextLimit` is nil, `nil` when `contextLimit` is zero, and correct values at 25%, 85%, and 100%.

- [ ] **Add unit tests for `Sanitizer.sanitize(headers:)`** — once `Sanitizer` is implemented, add tests proving that `Authorization`, `x-api-key`, and `cookie` headers are redacted and that `Content-Type` is preserved.

---

## Trace Fixtures

- [ ] **Add a multi-turn conversation fixture** — create `Packages/ContextScopeDemoData/Sources/ContextScopeDemoData/Fixtures/multi_turn.contextscope.json` following the schema in `Docs/TraceFormat.md`. Use only fictional content.

- [ ] **Validate existing fixtures against TraceFormat.md** — write a Swift test that decodes all three fixture files and asserts the required fields are present.

---

## Tooling

- [ ] **Add a `validate-traces.sh` script** — in `Scripts/`, write a Bash script that checks every `*.contextscope.json` under `Packages/` and `Examples/` for required fields (`version`, `frames`, at least one item per frame). Exit non-zero if any file fails.

- [ ] **Pin the Xcode version in CI** — update `.github/workflows/ci.yml` to use the latest stable Xcode 15.x release and document the choice.

---

## Examples

- [ ] **Add a Python streaming example** — in `Examples/python/streaming_chat.py`, show how to consume SSE chunks from the proxy using the `openai` SDK with `stream=True`.

- [ ] **Add a Node.js streaming example** — in `Examples/nodejs/streaming_chat.js`, show the same using the `openai` npm package with `stream: true`.
