#!/usr/bin/env bash
# Ad-hoc codesign the built binary with network entitlements.
# Required because SPM executables don't have an Xcode entitlements phase.
set -euo pipefail

BINARY=".build/debug/ContextScopeApp"
ENTITLEMENTS="App/ContextScopeApp/Resources/ContextScopeApp.entitlements"

if [ ! -f "$BINARY" ]; then
    echo "Binary not found at $BINARY — run 'swift build' first."
    exit 1
fi

codesign \
    --force \
    --sign - \
    --entitlements "$ENTITLEMENTS" \
    "$BINARY"

echo "Signed: $BINARY"
