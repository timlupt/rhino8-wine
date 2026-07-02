# Install with Home Manager

## 1. Add to home.nix

```nix
{
  imports = [
    (builtins.getFlake "github:timlupt/rhino8-wine").homeManagerModules.default
  ];

  programs.rhino8 = {
    enable = true;
    desktopIntegration = true;  # Creates desktop entry
  };
}
```

## 2. Apply home-manager

```bash
home-manager switch
```

## 3. Install Rhino

Download installer, then:

```bash
install-rhino ~/Downloads/rhino_en-us_8.*.exe
```

## 4. Launch

From application menu: "Rhino 8"

Or command line:
```bash
run-rhino
```

## What you get

Commands in PATH:
- `run-rhino` - Launch Rhino 8
- `yak-rhino` - Package manager
- `rhino-uninstall` - Uninstall
- `rhino-analyze-crash` - Debug tool

Desktop entry: "Rhino 8" in application menu
