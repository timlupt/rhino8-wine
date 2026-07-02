#!/usr/bin/env bash
# Fix: Black Menus
# Disables WPF hardware acceleration to fix black rendering

fix_name="black_menus"
fix_description="WPF black menus fix"

apply_fix() {
    log_info "Applying $fix_description..."

    wine_reg_add "HKCU\\Software\\Microsoft\\Avalon.Graphics" \
        "DisableHWAcceleration" \
        "REG_DWORD" \
        "1"

    log_success "Black menus fix applied"
}

remove_fix() {
    log_info "Removing $fix_description..."

    wine_reg_delete "HKCU\\Software\\Microsoft\\Avalon.Graphics" \
        "DisableHWAcceleration"

    log_success "Black menus fix removed"
}

test_fix() {
    if wine_reg_exists "HKCU\\Software\\Microsoft\\Avalon.Graphics" "DisableHWAcceleration"; then
        echo "✓ Applied (WPF HW accel disabled)"
        return 0
    else
        echo "✗ Not applied"
        return 1
    fi
}
