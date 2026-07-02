# Rhino 8 on Linux

Run **Rhinoceros 8** on Linux using Wine with Nix. Clean, simple, fully cached builds.

<img src="desktop_screenshot.jpeg" width="600" alt="Rhino 8 on Ubuntu" />

---

## Quick Start

### 1. Install Nix

**Determinate Systems Installer** (recommended):
```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

**Or Official Nix Installer**:
```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```

After installation, restart your shell or run:
```bash
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

### 2. Install Rhino

```bash
nix run github:timlupt/rhino8-wine#rhino8-install -- ~/Downloads/rhino_*.exe
```

This automatically:
- ✅ Downloads pre-built Wine with patches (cached, ~30 seconds)
- ✅ Installs Rhino 8 with all dependencies
- ✅ Applies compatibility fixes (black menus, fonts, MIDI)

### 3. Run Rhino

```bash
nix run github:timlupt/rhino8-wine#rhino8
```

**That's it!** No manual compilation, no dependencies to install.

---

## Home Manager Integration (Recommended)

For declarative installation with desktop integration:

```nix
{
  inputs.rhino8-wine = {
    url = "github:timlupt/rhino8-wine";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  imports = [ inputs.rhino8-wine.homeManagerModules.default ];

  programs.rhino8 = {
    enable = true;
    desktopIntegration = true;  # Creates application menu entry
    installTools = true;         # Installs all tools
  };
}
```

This provides:
- `rhino8` - Launch Rhino
- `rhino8-install` - Install Rhino from .exe
- `rhino8-uninstall` - Remove installation
- `rhino8-sync` - Manage Wine compatibility fixes
- `yak` - Plugin manager
- `rhino8-analyze-crash` - Crash log analyzer
- Desktop entry in application menu

See [INSTALL-HOME-MANAGER.md](./INSTALL-HOME-MANAGER.md) for details.

---

## Features

✅ **Automatic Cachix** - Pre-built Wine cached at https://timlupt-rhino8-wine.cachix.org  
✅ **Compatibility fixes** - Black menus, fonts, MIDI device support  
✅ **Plugin manager** - Yak integration for Rhino plugins  
✅ **MCP integration** - Works with Rhino-MCP-Platform  
✅ **MIDI support** - Use MIDI controllers with Grasshopper  
✅ **Debug mode** - Full Wine logs with `--debug` flag  
✅ **Clean & reproducible** - Nix flake with pinned dependencies  

---

## Commands

### Plugin Management

```bash
yak search grasshopper
yak install Rhino-MCP-Platform
yak install MidiListener
yak list
```

### Fix Management

Three fixes are applied automatically during installation:

```bash
rhino8-sync black-menus test    # Check if WPF HW acceleration is disabled
rhino8-sync fonts test          # Check if system fonts are registered
rhino8-sync midi test           # Check if MIDI driver is enabled
```

To reapply or remove fixes:
```bash
rhino8-sync <fix-name> apply    # Apply fix
rhino8-sync <fix-name> remove   # Remove fix
rhino8-sync <fix-name> test     # Test if applied
```

### Debug Mode

```bash
rhino8 --debug
```

Saves full Wine debug logs to `~/.local/share/wineprefixes/rhino8/logs/`

---

## What's Fixed

### Wine Patches (included)
1. **uxtheme.dll** - Dark mode recursion fix (prevents stack overflow)
2. **wintrust.dll** - Authenticode bypass (installer verification)

### Compatibility Fixes (applied automatically)
3. **black-menus** - Disables WPF hardware acceleration to fix black UI rendering
4. **fonts** - Registers system fonts via Z:\ paths to fix WPF text rendering and color picker
5. **midi** - Enables Wine ALSA MIDI driver for device enumeration in Grasshopper

All fixes are applied during `rhino8-install` and can be managed with `rhino8-sync`.

---

## Technical Details

### The Problem

Rhino 8 uses .NET 8 and caused a stack overflow in Wine:

```
err:virtual:virtual_setup_exception stack overflow 4672 bytes addr 0x6ffffff85ebe
```

**Root cause:** Dark mode detection caused 254,955-deep mutual recursion. Rhino's `RhOSInDarkMode` probe resolved four undocumented `uxtheme.dll` immersive-color exports at runtime; Wine didn't provide them, so the probe fell back to a managed callback that re-entered it, recursing until stack overflow.

**Solution:** Added the missing exports to Wine's `uxtheme` (in `rhino8-wine.patch`) — **no patching of Rhino's own DLLs required.**

See [WINE_PORTING_NOTES.md](WINE_PORTING_NOTES.md) for detailed writeup.

---

## MIDI Setup

To use MIDI controllers with Grasshopper:

1. Install MidiListener plugin: `yak install MidiListener`
2. Restart Rhino for plugin to load
3. Connect your MIDI device
4. In Grasshopper, use MidiListener components to read CC values
5. Remap MIDI range (0-127) to your desired range (e.g., 0-π radians)

The `midi` fix enables Wine's ALSA MIDI driver so Windows applications can enumerate MIDI devices.

---

## Manual Build (Advanced)

If you need to build from source or modify the flake:

```bash
git clone https://github.com/timlupt/rhino8-wine
cd rhino8-wine
nix build .#wine-rhino --print-build-logs
```

Build time: ~30-40 minutes first time, then cached.

---

## Contributing

Technical documentation:
- [UXTHEME-MR.md](./UXTHEME-MR.md) - uxtheme implementation details
- [WINE_PORTING_NOTES.md](./WINE_PORTING_NOTES.md) - Complete problem analysis
- [KNOWN-ISSUES.md](KNOWN-ISSUES.md) - Known limitations and workarounds

## Credits

- Original patches: [ItHasLegs/rhino8-wine](https://github.com/ItHasLegs/rhino8-wine)
- Nix flake & fixes: This repository

---

**Tested on:**
- Ubuntu 24.04.4 LTS (Kernel 6.17)
- Fedora 43 (Kernel 7.1)
- Rhino 8.32.26160.13001

_This project was developed with assistance from Claude Code._
