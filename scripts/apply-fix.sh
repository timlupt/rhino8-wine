#!/usr/bin/env bash
# Apply individual fixes to Rhino Wine prefix

set -euo pipefail

# Get directories - use RHINO_* env vars if set (from nix package), else use relative path
if [[ -n "${RHINO_SCRIPTS:-}" ]]; then
    SCRIPT_DIR="$RHINO_SCRIPTS"
    FIXES_DIR="${RHINO_FIXES:-$(dirname "$RHINO_SCRIPTS")/fixes}"
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    FIXES_DIR="$(dirname "$SCRIPT_DIR")/fixes"
fi

# Load libraries
# shellcheck source=scripts/lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=scripts/lib/registry.sh
source "$SCRIPT_DIR/lib/registry.sh"

PREFIX="${WINEPREFIX:-$HOME/.local/share/wineprefixes/rhino8}"

if [[ ! -d "$PREFIX" ]]; then
    log_error "Wine prefix not found: $PREFIX"
    exit 1
fi

# Show usage
if [[ $# -eq 0 ]]; then
    echo "Apply Rhino fixes"
    echo ""
    echo "Usage: $0 <fix-name> [action]"
    echo ""
    echo "Fixes:"
    echo "  black-menus  - Fix black WPF menus"
    echo "  fonts        - Register system fonts for WPF"
    echo ""
    echo "Actions:"
    echo "  apply   - Apply fix (default)"
    echo "  remove  - Remove fix"
    echo "  test    - Test if fix is applied"
    echo ""
    echo "Example:"
    echo "  $0 black-menus apply"
    echo "  $0 fonts test"
    exit 0
fi

FIX_NAME="$1"
ACTION="${2:-apply}"

# Load the fix
FIX_FILE="$FIXES_DIR/$FIX_NAME.sh"

if [[ ! -f "$FIX_FILE" ]]; then
    log_error "Fix not found: $FIX_NAME"
    echo "Available fixes:"
    for f in "$FIXES_DIR"/*.sh; do
        echo "  - $(basename "$f" .sh)"
    done
    exit 1
fi

# shellcheck source=/dev/null
source "$FIX_FILE"

# Run the action
case "$ACTION" in
    apply)
        apply_fix
        ;;
    remove)
        remove_fix
        ;;
    test)
        echo -n "$fix_description: "
        test_fix
        ;;
    *)
        log_error "Unknown action: $ACTION"
        exit 1
        ;;
esac
