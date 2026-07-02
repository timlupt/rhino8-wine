#!/usr/bin/env bash
# Common functions for rhino8-wine scripts

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $*"
}

log_success() {
    echo -e "${GREEN}✓${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*" >&2
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get Wine prefix (with fallback)
get_wine_prefix() {
    echo "${WINEPREFIX:-$HOME/.local/share/wineprefixes/rhino8}"
}

# Get Rhino executable path
get_rhino_exe() {
    local prefix
    prefix=$(get_wine_prefix)
    echo "$prefix/drive_c/Program Files/Rhino 8/System/Rhino.exe"
}

# Check if Rhino is installed
is_rhino_installed() {
    local rhino_exe
    rhino_exe=$(get_rhino_exe)
    [[ -f "$rhino_exe" ]]
}

# Create backup of Wine prefix
backup_prefix() {
    local prefix timestamp backup_dir
    prefix=$(get_wine_prefix)
    timestamp=$(date +%Y%m%d-%H%M%S)
    backup_dir="$prefix.backup-$timestamp"

    if [[ -d "$prefix" ]]; then
        log_info "Backing up Wine prefix..."
        cp -a "$prefix" "$backup_dir"
        log_success "Backup created: $backup_dir"
        echo "$backup_dir"
    fi
}

# Reset Wine prefix
reset_prefix() {
    local prefix
    prefix=$(get_wine_prefix)

    if [[ -d "$prefix" ]]; then
        log_warn "Deleting Wine prefix: $prefix"
        rm -rf "$prefix"
        log_success "Prefix deleted"
    fi
}

# Create fresh Wine prefix
create_prefix() {
    local prefix
    prefix=$(get_wine_prefix)

    log_info "Creating fresh Wine prefix..."
    WINEPREFIX="$prefix" WINEDEBUG=fixme-all wine wineboot
    log_success "Prefix created: $prefix"
}
