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
echo "==> Resolving Swift Package Manager dependencies"

for pkg in ContextScopeCore ContextScopeCapture ContextScopeStorage ContextScopeDemoData; do
  echo "  Resolving Packages/$pkg..."
  swift package resolve --package-path "Packages/$pkg" 2>&1 | tail -1
done

echo ""
echo "==> Building packages"

for pkg in ContextScopeCore ContextScopeCapture ContextScopeStorage ContextScopeDemoData; do
  echo "  Building Packages/$pkg..."
  swift build --package-path "Packages/$pkg" -q
done

echo ""
echo "Bootstrap complete."
echo ""
echo "Next steps:"
echo "  1. Open the app in Xcode:"
echo "       open App/ContextScopeApp/ContextScopeApp.xcworkspace"
echo "  2. Build and run the ContextScopeApp scheme."
echo "  3. To run tests: ./Scripts/test.sh"
echo "  4. To run Demo Mode without an API key: ./Scripts/run-demo.sh"
