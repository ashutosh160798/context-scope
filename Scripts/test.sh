#!/usr/bin/env bash
set -euo pipefail

echo "==> ContextScope test suite"
echo ""

FAILED=0

for pkg in ContextScopeCore ContextScopeCapture ContextScopeStorage ContextScopeDemoData; do
  echo "--- $pkg ---"
  if swift test --package-path "Packages/$pkg"; then
    echo "PASS: $pkg"
  else
    echo "FAIL: $pkg" >&2
    FAILED=$((FAILED + 1))
  fi
  echo ""
done

echo "Note: ContextScopeVisualization uses SwiftUI — test it from Xcode."
echo ""

if [ "$FAILED" -gt 0 ]; then
  echo "FAILED: $FAILED package(s) had test failures." >&2
  exit 1
else
  echo "All tests passed."
fi
