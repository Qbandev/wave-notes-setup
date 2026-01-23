#!/bin/bash
# Run all tests for wave-notes-setup
# Usage: ./test/run_tests.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "================================"
echo "wave-notes-setup Test Suite"
echo "================================"
echo ""

# Check for bats
if ! command -v bats >/dev/null 2>&1; then
    echo "ERROR: bats is not installed"
    echo ""
    echo "Install with:"
    echo "  brew install bats-core"
    echo ""
    exit 1
fi

# Check for shellcheck (optional but recommended)
if command -v shellcheck >/dev/null 2>&1; then
    echo "Running ShellCheck..."
    echo "────────────────────"
    shellcheck install.sh uninstall.sh && echo "✓ ShellCheck passed" || echo "⚠ ShellCheck found issues"
    echo ""
else
    echo "⚠ shellcheck not installed (skipping)"
    echo "  Install with: brew install shellcheck"
    echo ""
fi

# Run bats tests
echo "Running Bats tests..."
echo "────────────────────"
bats test/*.bats

echo ""
echo "================================"
echo "All tests completed!"
echo "================================"
