#!/usr/bin/env bash
# Uninstall Rhino 8

set -euo pipefail

PREFIX="${HOME}/.local/share/wineprefixes/rhino8"

echo "Rhino 8 Uninstall"
echo "─────────────────"
echo ""
echo "This will remove:"
echo "  • Wine prefix: $PREFIX"
echo "  • All Rhino data and settings"
echo ""
read -p "Continue? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 0
fi

if [[ -d "$PREFIX" ]]; then
    echo "Removing Wine prefix..."
    rm -rf "$PREFIX"
    echo "✓ Uninstalled"
else
    echo "Nothing to remove"
fi
