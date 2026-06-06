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
