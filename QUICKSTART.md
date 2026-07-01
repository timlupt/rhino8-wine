# Rhino 8 on Linux - Quick Start

Clean, simple Nix flake for running Rhino 8 on Linux with Wine.

## Quick Install

```bash
# Install Rhino
nix run github:timlupt/rhino8-wine#install -- ~/Downloads/rhino_*.exe

# Apply fixes (one-time)
nix run github:timlupt/rhino8-wine#fix-ui-lag
nix run github:timlupt/rhino8-wine#fix-black-menus

# Run Rhino
nix run github:timlupt/rhino8-wine#run
```

## Commands

### Installation
```bash
nix run .#install -- <rhino-installer.exe>
```
Shows progress during installation (~10-15 minutes).

### Running
```bash
nix run .#run              # Normal mode
nix run .#run -- --debug   # Debug mode with full logs
```

### Plugin Management
```bash
nix run .#yak -- search <query>
nix run .#yak -- install <package>
nix run .#yak -- list
```

### Fixes

**UI Lag Fix** (must run once):
```bash
nix run .#fix-ui-lag
```
Fixes:
- Bottom buttons not updating until mouse-over
- High CPU usage
- Toolbar icons not appearing

**Black Menus Fix** (must run once):
```bash
nix run .#fix-black-menus
```
Fixes:
- Black layer panel
- Black menus and dialogs

## What's Included

- ✅ Wine with Rhino patches (uxtheme dark mode, wintrust bypass)
- ✅ AMD/Intel GPU acceleration
- ✅ Automatic Wine cleanup after exit
- ✅ MFC UI lag fix
- ✅ WPF black menu fix
- ✅ en-US locale (prevents MCP font crashes)
- ✅ Debug logging option

## Cachix

Pre-built binaries available from Cachix (optional):

```bash
cachix use YOUR_CACHE_NAME
nix build .#wine-rhino
```

## GitHub Actions

Automatically builds and caches Wine on push.

**Setup:**
1. Create Cachix account
2. Add `CACHIX_AUTH_TOKEN` to repository secrets
3. Update cache name in `.github/workflows/build.yml`
