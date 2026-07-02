#!/usr/bin/env bash
# Run Yak (Rhino package manager)

set -euo pipefail

PREFIX="${HOME}/.local/share/wineprefixes/rhino8"
YAK_EXE="$PREFIX/drive_c/Program Files/Rhino 8/System/Yak.exe"

if [[ ! -f "$YAK_EXE" ]]; then
    echo "Error: Rhino not installed"
    exit 1
fi

# Show help if no arguments
if [[ $# -eq 0 ]]; then
    echo "Yak Package Manager"
    echo ""
    echo "Usage: yak-rhino <command> [args]"
    echo ""
    echo "Commands:"
    echo "  search <query>      - Search for packages"
    echo "  install <package>   - Install a package"
    echo "  uninstall <package> - Uninstall a package"
    echo "  list                - List installed packages"
    echo ""
    echo "Example:"
    echo "  yak-rhino install Rhino-MCP-Platform"
    exit 0
fi

WINEPREFIX="$PREFIX" WINEDEBUG=-all wine "$YAK_EXE" "$@"
