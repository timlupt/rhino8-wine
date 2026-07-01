# Rhino 8 on Linux - Quick Start

Clean, simple Nix flake for running Rhino 8 on Linux with Wine.

## Quick Install

```bash
# Install Rhino (fixes applied automatically)
nix run github:timlupt/rhino8-wine#install -- ~/Downloads/rhino_*.exe

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

### Fixes (Optional)

Fixes are **automatically applied during installation**. These commands are only needed to re-apply or adjust settings.

**UI Lag Fix** (optional, to adjust throttle interval):
```bash
nix run .#fix-ui-lag           # Default: 50ms
nix run .#fix-ui-lag -- 25     # Faster: 25ms
nix run .#fix-ui-lag -- 100    # Slower: 100ms
```
Fixes:
- Bottom buttons not updating until mouse-over
- High CPU usage
- Toolbar icons not appearing

**Black Menus Fix** (optional, to re-apply):
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

Pre-built binaries **automatically used** from Cachix (no setup needed):

```bash
# Just build - cache is configured in flake.nix
nix build github:timlupt/rhino8-wine#wine-rhino

# Or run directly:
nix run github:timlupt/rhino8-wine#install -- ~/Downloads/rhino_*.exe
```

The cache is automatically trusted when you use the flake!

## GitHub Actions

Automatically builds and caches Wine on push.

**Setup:**
1. Create Cachix account
2. Add `CACHIX_AUTH_TOKEN` to repository secrets
3. Update cache name in `.github/workflows/build.yml`
