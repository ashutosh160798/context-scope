# Sample Traces

These `.contextscope.json` files are example traces that can be loaded into ContextScope for testing and development.

| File | Scenario | Description |
|---|---|---|
| See `Packages/ContextScopeDemoData/Sources/ContextScopeDemoData/Fixtures/` | All demo scenarios | The three built-in Demo Mode fixtures |

## Creating your own trace

1. Start the ContextScope proxy
2. Route traffic through `http://127.0.0.1:4319/v1`
3. Complete a session
4. In ContextScope, choose File > Export Trace

Or create one manually following [`Docs/TraceFormat.md`](../../Docs/TraceFormat.md).

## Validating a trace

> `Scripts/validate-traces.sh` is not yet implemented. It is tracked as a starter issue in [`Docs/StarterIssues.md`](../../Docs/StarterIssues.md).
