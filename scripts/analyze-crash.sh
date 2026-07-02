#!/usr/bin/env bash
# Analyze Rhino crash logs

set -euo pipefail

PREFIX="${HOME}/.local/share/wineprefixes/rhino8"
LOGDIR="$PREFIX/logs"

if [[ ! -d "$LOGDIR" ]]; then
    echo "No logs found at $LOGDIR"
    exit 1
fi

# Find most recent stderr log
LATEST_ERR=$(ls -t "$LOGDIR"/rhino*stderr*.log 2>/dev/null | head -1)

if [[ -z "$LATEST_ERR" ]]; then
    echo "No stderr logs found"
    exit 1
fi

echo "Analyzing: $LATEST_ERR"
echo ""
echo "╔════════════════════════════════════════════════════╗"
echo "║   CRASH ANALYSIS                                   ║"
echo "╚════════════════════════════════════════════════════╝"
echo ""

# .NET FailFast
if grep -q "FailFast" "$LATEST_ERR"; then
    echo "🔴 .NET FailFast detected:"
    echo "─────────────────────────────────────────"
    grep -A 5 "FailFast" "$LATEST_ERR" | head -20
    echo ""
fi

# Unhandled exceptions
if grep -q "Unhandled exception" "$LATEST_ERR"; then
    echo "🔴 Unhandled Exception:"
    echo "─────────────────────────────────────────"
    grep -B 5 -A 10 "Unhandled exception" "$LATEST_ERR" | head -30
    echo ""
fi

# Wine errors
if grep -q "err:" "$LATEST_ERR"; then
    echo "⚠️  Wine Errors (last 20):"
    echo "─────────────────────────────────────────"
    grep "err:" "$LATEST_ERR" | tail -20
    echo ""
fi

# Stack trace
if grep -q "at System\|at MS\." "$LATEST_ERR"; then
    echo "📋 .NET Stack Trace:"
    echo "─────────────────────────────────────────"
    awk '/at System|at MS\./ {print; count++} count>=15 {exit}' "$LATEST_ERR"
    echo ""
fi

echo "═══════════════════════════════════════════════════════"
echo "Full log: $LATEST_ERR"
