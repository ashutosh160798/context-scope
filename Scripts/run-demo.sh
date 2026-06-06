#!/usr/bin/env bash
set -euo pipefail

echo "==> ContextScope Demo Mode"
echo ""
echo "Building..."
swift build -q

echo ""
echo "Launching ContextScope in Demo Mode..."
echo "(The app will open — click 'Play Demo' to start, or select a scenario from the sidebar.)"
echo ""
swift run ContextScopeApp
