#!/usr/bin/env bash
# Install Rhino 8 with Wine

set -euo pipefail

# Check arguments
if [[ $# -eq 0 ]]; then
    echo "Usage: install-rhino <rhino-installer.exe>"
    echo ""
    echo "Example:"
    echo "  install-rhino ~/Downloads/rhino_en-us_8.*.exe"
    exit 1
fi

INSTALLER="$1"
PREFIX="${HOME}/.local/share/wineprefixes/rhino8"

if [[ ! -f "$INSTALLER" ]]; then
    echo "Error: File not found: $INSTALLER"
    exit 1
fi

echo "╔════════════════════════════════════════════╗"
echo "║   Rhino 8 Wine - Installation              ║"
echo "╚════════════════════════════════════════════╝"
echo ""
echo "Installing to: $PREFIX"
echo ""

# Create Wine prefix
echo "Creating Wine prefix..."
WINEPREFIX="$PREFIX" WINEDEBUG=fixme-all wine wineboot
echo "✓ Wine prefix created"
echo ""

# Disable Wine menu builder (desktop integration via home-manager)
export WINEDLLOVERRIDES="winemenubuilder.exe=d"

# Install Rhino
echo "Starting Rhino installer..."
echo ""
echo "The installer will:"
echo "  • Install .NET 8 Desktop Runtime (large download)"
echo "  • Install Visual C++ runtimes"
echo "  • Install WebView2"
echo "  • Install Rhino 8"
echo ""
echo "Progress shown below (~10-15 minutes):"
echo "─────────────────────────────────────────"
echo ""

WINEPREFIX="$PREFIX" WINEDEBUG=fixme-all,err+all wine "$INSTALLER"

echo ""

# Check if installed
RHINO_EXE="$PREFIX/drive_c/Program Files/Rhino 8/System/Rhino.exe"
if [[ ! -f "$RHINO_EXE" ]]; then
    echo "Error: Installation may have failed"
    echo "Check logs for errors"
    exit 1
fi

echo "✓ Rhino installation complete!"
echo ""

# Apply fixes automatically
echo "ℹ Applying fixes..."

# Load libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -n "${RHINO_SCRIPTS:-}" ]]; then
    # shellcheck source=scripts/lib/common.sh
    source "$RHINO_SCRIPTS/lib/common.sh"
    # shellcheck source=scripts/lib/registry.sh
    source "$RHINO_SCRIPTS/lib/registry.sh"
    FIXES_DIR="$RHINO_FIXES"
else
    # shellcheck source=scripts/lib/common.sh
    source "$SCRIPT_DIR/lib/common.sh"
    # shellcheck source=scripts/lib/registry.sh
    source "$SCRIPT_DIR/lib/registry.sh"
    FIXES_DIR="$(dirname "$SCRIPT_DIR")/fixes"
fi

# Apply fixes
for fix in black-menus fonts; do
    # shellcheck source=/dev/null
    source "$FIXES_DIR/$fix.sh"
    apply_fix
done

echo ""
echo "✓ Setup complete"
echo ""
echo "Run with: rhino8"
echo "Manage packages: yak"
