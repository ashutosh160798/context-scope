#!/usr/bin/env bash
# Run all tests: root package (app tests) + each sub-package.
set -euo pipefail

FAILED=0

run_tests() {
    local label="$1"
    local path="$2"
    echo "--- $label ---"
    if swift test --package-path "$path"; then
        echo "PASS: $label"
    else
        echo "FAIL: $label" >&2
        FAILED=$((FAILED + 1))
    fi
    echo ""
}

echo "==> ContextScope test suite"
echo ""

# Root package (app-level tests)
run_tests "ContextScopeApp" "."

# Sub-packages
for pkg in ContextScopeCore ContextScopeCapture ContextScopeStorage ContextScopeDemoData ContextScopeVisualization; do
    run_tests "$pkg" "Packages/$pkg"
done

if [ "$FAILED" -gt 0 ]; then
    echo "FAILED: $FAILED suite(s) had failures." >&2
    exit 1
else
    echo "All tests passed."
fi
