#!/usr/bin/env bash
# WPF font rendering fix - register system fonts via Z:\ paths

fix_name="fonts"
fix_description="WPF font rendering fix"

apply_fix() {
    log_info "Registering system fonts via Z:\\ paths..."

    # Find Liberation or GNU FreeFont (Arial/Times compatible)
    local font_found=false

    # Try Liberation Sans (best Arial replacement)
    if [ -f "/usr/share/fonts/liberation-sans/LiberationSans-Regular.ttf" ]; then
        wine_reg_add "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Fonts" \
            "Liberation Sans (TrueType)" "REG_SZ" \
            "Z:\\usr\\share\\fonts\\liberation-sans\\LiberationSans-Regular.ttf"
        wine_reg_add "HKCU\\Software\\Wine\\Fonts\\Replacements" \
            "Arial" "REG_SZ" "Liberation Sans"
        font_found=true
    fi

    # Try GNU FreeSans as fallback
    if [ -f "/usr/share/fonts/gnu-free/FreeSans.ttf" ]; then
        wine_reg_add "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Fonts" \
            "FreeSans (TrueType)" "REG_SZ" \
            "Z:\\usr\\share\\fonts\\gnu-free\\FreeSans.ttf"
        if [ "$font_found" = false ]; then
            wine_reg_add "HKCU\\Software\\Wine\\Fonts\\Replacements" \
                "Arial" "REG_SZ" "FreeSans"
        fi
        font_found=true
    fi

    if [ "$font_found" = true ]; then
        log_success "System fonts registered via Z:\\ paths"
    else
        log_warn "No suitable system fonts found"
    fi
}

remove_fix() {
    log_info "Removing font registry entries..."

    wine_reg_delete "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Fonts" \
        "Liberation Sans (TrueType)" 2>/dev/null || true
    wine_reg_delete "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Fonts" \
        "FreeSans (TrueType)" 2>/dev/null || true
    wine_reg_delete "HKCU\\Software\\Wine\\Fonts\\Replacements" \
        "Arial" 2>/dev/null || true

    log_success "Font entries removed"
}

test_fix() {
    if wine_reg_exists "HKCU\\Software\\Wine\\Fonts\\Replacements" "Arial"; then
        local replacement=$(wine_reg_query "HKCU\\Software\\Wine\\Fonts\\Replacements" "Arial" 2>/dev/null | grep -oP '(?<=REG_SZ    ).*')
        echo "✓ Applied (Arial → $replacement)"
        return 0
    else
        echo "✗ Not applied"
        return 1
    fi
}
