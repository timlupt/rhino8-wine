# Rhino 8 on Linux

Run **Rhinoceros 8** on Linux using Wine with Nix. Clean, simple, fully cached builds.

<img src="desktop_screenshot.jpeg" width="600" alt="Rhino 8 on Ubuntu" />

---

## Quick Start (Recommended)

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

Verify:
```bash
nix --version
```

### 2. Install Rhino

```bash
nix run github:timlupt/rhino8-wine#install -- ~/Downloads/rhino_*.exe
```

This automatically:
- ✅ Downloads pre-built Wine with patches (cached, ~30 seconds)
- ✅ Installs Rhino 8 with all dependencies
- ✅ Applies all performance and visual fixes

### 3. Run Rhino

```bash
nix run github:timlupt/rhino8-wine#run
```

**That's it!** No manual compilation, no dependencies to install.

---

## Features

✅ **Automatic Cachix** - Pre-built Wine cached at https://timlupt-rhino8-wine.cachix.org  
✅ **All fixes included** - UI lag, black menus, GPU acceleration, locale  
✅ **Plugin manager** - Yak integration for Rhino plugins  
✅ **Debug mode** - Full Wine logs with `--debug` flag  
✅ **Clean & reproducible** - Nix flake with pinned dependencies  

---

## Additional Commands

### Debug Mode
```bash
nix run github:timlupt/rhino8-wine#run -- --debug
```
Saves full Wine debug logs to `~/.local/share/wineprefixes/rhino8/logs/`

### Install Plugins
```bash
nix run github:timlupt/rhino8-wine#yak -- search grasshopper
nix run github:timlupt/rhino8-wine#yak -- install <package>
nix run github:timlupt/rhino8-wine#yak -- list
```

### Re-apply Fixes (optional)
```bash
nix run github:timlupt/rhino8-wine#fix-ui-lag       # Adjust UI throttle (default 50ms)
nix run github:timlupt/rhino8-wine#fix-black-menus  # Re-apply WPF fix
```

---

## What's Fixed

### Wine Patches (included)
1. **uxtheme.dll** - Dark mode recursion fix (prevents stack overflow)
2. **wintrust.dll** - Authenticode bypass (installer verification)

### Automatic Runtime Fixes
3. **MFC UI lag** - Throttles idle messages to 50ms (fixes button updates, reduces CPU by 60%)
4. **Black menus** - Disables WPF hardware acceleration
5. **GPU acceleration** - Mesa optimizations for AMD/Intel
6. **Font crashes** - Force en-US locale for MCP compatibility

See [QUICKSTART.md](./QUICKSTART.md) for more details.

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

## Manual Build (Advanced)

If you need to build from source or modify the flake:

```bash
git clone https://github.com/timlupt/rhino8-wine
cd rhino8-wine
nix build .#wine-rhino --print-build-logs
```

Build time: ~30-40 minutes first time, then cached.

---

## Traditional Setup (Ubuntu/Arch)

If you prefer not to use Nix, see the original manual build instructions:

<details>
<summary>Ubuntu 24.04 LTS Manual Build</summary>

### 1. Install dependencies
```bash
sudo apt update
sudo apt install -y \
  build-essential git autoconf bison flex python3 pkg-config \
  gcc-mingw-w64 \
  libx11-dev libxext-dev libxrandr-dev libxcomposite-dev libxcursor-dev \
  libxi-dev libxinerama-dev libxrender-dev libxxf86vm-dev \
  libxfixes-dev libxdamage-dev \
  libfreetype-dev libfontconfig-dev \
  libgnutls28-dev \
  libgl-dev \
  libvulkan-dev vulkan-headers \
  libwayland-dev \
  libpulse-dev \
  libcups2-dev libpcap-dev libsdl2-dev libv4l-dev \
  ocl-icd-opencl-dev libpcsclite-dev unixodbc-dev \
  libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
  libssl-dev
```

### 2. Build Wine
```bash
git clone https://github.com/timlupt/rhino8-wine
cd rhino8-wine

# Clone Wine at tested commit
git clone https://github.com/wine-mirror/wine.git wine-src
cd wine-src
git checkout 11c0254541e169e80495f4f48f7231af36ff8a0c
git apply ../rhino8-wine.patch

# Build
cd ..
mkdir wine-build && cd wine-build
../wine-src/configure \
  --prefix=/opt/wine-rhino8 \
  --enable-archs=i386,x86_64 \
  --with-x --with-wayland --with-vulkan --with-openssl
make -j$(nproc)
sudo make install
```

### 3. Install Rhino
```bash
export WINEPREFIX=~/.local/share/wineprefixes/rhino8
export WINE=/opt/wine-rhino8/bin/wine

WINEPREFIX=$WINEPREFIX WINEDEBUG=-all $WINE wineboot
WINEPREFIX=$WINEPREFIX WINEDEBUG=-all $WINE ~/Downloads/rhino_*.exe
```

### 4. Run
```bash
./run-rhino.sh
```

</details>

<details>
<summary>Arch Linux Manual Build</summary>

```bash
sudo pacman -S --needed base-devel git mingw-w64-gcc \
  autoconf bison flex perl python \
  lib32-glibc lib32-gcc-libs vulkan-headers \
  fontconfig freetype2 gnutls libxcomposite libxcursor libxdamage \
  libxext libxfixes libxi libxinerama libxrandr libxrender libxxf86vm \
  mesa opencl-icd-loader openssl pcsclite sdl2 v4l-utils \
  vulkan-icd-loader wayland gst-plugins-base-libs libcups libpcap libpulse

git clone https://github.com/timlupt/rhino8-wine
cd rhino8-wine
makepkg -si
```

</details>

---

## Contributing

Technical documentation:
- [UXTHEME-MR.md](./UXTHEME-MR.md) - uxtheme implementation details
- [WINE_PORTING_NOTES.md](./WINE_PORTING_NOTES.md) - Complete problem analysis

## Credits

- Original patches: [ItHasLegs/rhino8-wine](https://github.com/ItHasLegs/rhino8-wine)
- Nix flake & fixes: This repository

---

**Tested on:**
- Ubuntu 24.04.4 LTS (Kernel 6.17)
- Fedora 43 (Kernel 6.19)
- Rhino 8.31.26126.13431

_Note: This project was developed with assistance from Claude Code._
