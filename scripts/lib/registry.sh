#!/usr/bin/env bash
# Wine registry helper functions

# Add registry value
wine_reg_add() {
    local key="$1"
    local name="$2"
    local type="$3"
    local value="$4"
    local prefix

    prefix=$(get_wine_prefix)

    WINEPREFIX="$prefix" wine reg add "$key" \
        /v "$name" /t "$type" /d "$value" /f >/dev/null 2>&1
    return 0
}

# Delete registry value
wine_reg_delete() {
    local key="$1"
    local name="$2"
    local prefix

    prefix=$(get_wine_prefix)

    WINEPREFIX="$prefix" wine reg delete "$key" /v "$name" /f >/dev/null 2>&1
}

# Query registry value
wine_reg_query() {
    local key="$1"
    local name="$2"
    local prefix

    prefix=$(get_wine_prefix)

    WINEPREFIX="$prefix" wine reg query "$key" /v "$name" 2>/dev/null
}

# Check if registry value exists
wine_reg_exists() {
    local key="$1"
    local name="$2"

    wine_reg_query "$key" "$name" >/dev/null 2>&1
}
