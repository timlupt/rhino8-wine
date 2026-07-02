#!/usr/bin/env bash
# Run Rhino 8 with Wine

set -euo pipefail

PREFIX="${HOME}/.local/share/wineprefixes/rhino8"
RHINO_EXE="$PREFIX/drive_c/Program Files/Rhino 8/System/Rhino.exe"
LOGDIR="$PREFIX/logs"
mkdir -p "$LOGDIR"

# Check if installed
if [[ ! -f "$RHINO_EXE" ]]; then
    echo "Error: Rhino not installed"
    echo "Install with: nix run .#install -- <installer.exe>"
    exit 1
fi

# Parse debug flag
DEBUG_MODE="normal"
if [[ "${1:-}" == "--debug" ]]; then
    DEBUG_MODE="full"
fi

TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Set debug level
if [[ "$DEBUG_MODE" == "full" ]]; then
    WINEDEBUG="warn+all,+seh,+eventlog,+mscoree"
    LOGFILE="$LOGDIR/rhino-debug-$TIMESTAMP.log"
    ERRFILE="$LOGDIR/rhino-debug-stderr-$TIMESTAMP.log"
    echo "ℹ Full debug mode enabled"
    echo "ℹ Stdout: $LOGFILE"
    echo "ℹ Stderr: $ERRFILE"
else
    WINEDEBUG="err+all,warn+seh,warn+eventlog"
    LOGFILE="$LOGDIR/rhino-$TIMESTAMP.log"
    ERRFILE="$LOGDIR/rhino-stderr-$TIMESTAMP.log"
fi

# Set environment
export LC_ALL="en_US.UTF-8"
export LANG="en_US.UTF-8"
export MESA_GL_VERSION_OVERRIDE="4.6"
export mesa_glthread=true

# .NET/WPF compatibility
export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=0
export DOTNET_EnableWriteXorExecute=0

# .NET debug in full mode
if [[ "$DEBUG_MODE" == "full" ]]; then
    export COREHOST_TRACE=1
    export COREHOST_TRACEFILE="$LOGDIR/dotnet-trace-$TIMESTAMP.log"
fi

# Cleanup function to kill all Wine subprocesses
cleanup() {
    echo ""
    echo "ℹ Cleaning up Wine processes..."
    if [[ -n "${WINE_PID:-}" ]]; then
        # Kill entire process group (negative PID kills the group)
        kill -TERM -- -$WINE_PID 2>/dev/null || true
        sleep 0.5
        kill -KILL -- -$WINE_PID 2>/dev/null || true
    fi
    # Also use wineserver cleanup for this prefix
    WINEPREFIX="$PREFIX" wineserver -k 2>/dev/null || true
}

# Register cleanup to run on script exit or interruption
trap cleanup EXIT INT TERM

echo "ℹ Starting Rhino 8..."
echo ""

# Run wine in background to enable process group tracking
set -m  # Enable job control
WINEPREFIX="$PREFIX" WINEDEBUG="$WINEDEBUG" \
    wine "$RHINO_EXE" > "$LOGFILE" 2> "$ERRFILE" &
WINE_PID=$!

# Wait for wine to finish (disable errexit for this)
set +e
wait $WINE_PID
WINE_EXIT_CODE=$?
set -e

# Cleanup happens automatically via trap
echo ""
echo "✓ Rhino exited (code: $WINE_EXIT_CODE)"
echo "ℹ Stdout log: $LOGFILE"
echo "ℹ Stderr log: $ERRFILE"

# Check for crashes
if grep -q "FailFast\|Unhandled exception\|Segmentation fault" "$ERRFILE" 2>/dev/null; then
    echo ""
    echo "⚠ CRASH DETECTED - Last 50 lines of stderr:"
    echo "════════════════════════════════════════════════════"
    tail -50 "$ERRFILE"
    echo "════════════════════════════════════════════════════"
fi
