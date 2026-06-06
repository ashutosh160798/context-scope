#!/usr/bin/env bash
set -euo pipefail

echo "==> ContextScope bootstrap"
echo ""

if ! command -v swift &>/dev/null; then
  echo "Error: swift not found. Install Xcode 15 or later." >&2
  exit 1
fi

SWIFT_VERSION=$(swift --version 2>&1 | head -1)
echo "Swift: $SWIFT_VERSION"

MACOS_VERSION=$(sw_vers -productVersion)
echo "macOS: $MACOS_VERSION"

echo ""
echo "==> Building root package (includes all modules + app)"
swift build -q

echo ""
echo "Bootstrap complete."
echo ""
echo "Next steps:"
echo "  Run demo:   swift run ContextScopeApp"
echo "  Run tests:  ./Scripts/test.sh"
