#!/usr/bin/env bash
# Fix: MIDI Device Support
# Registers Wine ALSA MIDI driver for device enumeration

fix_name="midi"
fix_description="MIDI device support"

apply_fix() {
    log_info "Registering Wine ALSA MIDI driver..."

    wine_reg_add "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Drivers32" \
        "midi" \
        "REG_SZ" \
        "winealsa.drv"

    wine_reg_add "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Drivers32" \
        "midimapper" \
        "REG_SZ" \
        "midimap.dll"

    wine_reg_add "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Drivers32" \
        "midi1" \
        "REG_SZ" \
        "winealsa.drv"

    log_success "MIDI driver registered"
}

remove_fix() {
    log_info "Removing MIDI driver registry entries..."

    wine_reg_delete "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Drivers32" \
        "midi" 2>/dev/null || true
    wine_reg_delete "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Drivers32" \
        "midimapper" 2>/dev/null || true
    wine_reg_delete "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Drivers32" \
        "midi1" 2>/dev/null || true

    log_success "MIDI driver entries removed"
}

test_fix() {
    if wine_reg_exists "HKLM\\Software\\Microsoft\\Windows NT\\CurrentVersion\\Drivers32" "midi"; then
        echo "✓ Applied (MIDI driver registered)"
        return 0
    else
        echo "✗ Not applied"
        return 1
    fi
}
