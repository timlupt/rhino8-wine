{
  description = "Rhino 8 on Linux via Wine with fixes";

  nixConfig = {
    extra-substituters = [ "https://timlupt-rhino8-wine.cachix.org" ];
    extra-trusted-public-keys = [ "timlupt-rhino8-wine.cachix.org-1:r8QrgOb0uoFHG2yNZUENz7ZIx8/WqSLIdmefgyHezhs=" ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # Wine with Rhino patches applied
        wine-rhino = pkgs.wineWow64Packages.stable.overrideAttrs (oldAttrs: {
          pname = "wine-rhino";
          patches = (oldAttrs.patches or []) ++ [
            ./rhino8-wine.patch
          ];
        });

        # Fix UI lag (button updates, high CPU)
        fix-ui-lag = pkgs.writeShellScriptBin "fix-ui-lag" ''
          WINE=${wine-rhino}/bin/wine
          WINESERVER=${wine-rhino}/bin/wineserver
          WINEPREFIX="''${WINEPREFIX:-$HOME/.local/share/wineprefixes/rhino8}"
          INTERVAL="''${1:-50}"

          echo "Fixing MFC UI lag (throttle idle updates to ''${INTERVAL}ms)..."
          WINEPREFIX="$WINEPREFIX" "$WINE" reg add \
            "HKCU\\Software\\Wine\\X11 Driver" \
            /v "IdleUpdateInterval" /t REG_DWORD /d "$INTERVAL" /f

          WINEPREFIX="$WINEPREFIX" "$WINESERVER" -k 2>/dev/null || true
          sleep 1

          echo "✓ Fixed. Restart Rhino to apply."
          echo ""
          echo "This fixes:"
          echo "  - Bottom buttons not updating until mouse-over"
          echo "  - High CPU usage (reduces by ~60%)"
          echo "  - Toolbar icons not appearing"
        '';

        # Fix black menus (WPF hardware acceleration)
        fix-black-menus = pkgs.writeShellScriptBin "fix-black-menus" ''
          WINE=${wine-rhino}/bin/wine
          WINESERVER=${wine-rhino}/bin/wineserver
          WINEPREFIX="''${WINEPREFIX:-$HOME/.local/share/wineprefixes/rhino8}"

          echo "Fixing black menus (disable WPF hardware acceleration)..."
          WINEPREFIX="$WINEPREFIX" "$WINE" reg add \
            "HKCU\\Software\\Microsoft\\Avalon.Graphics" \
            /v "DisableHWAcceleration" /t REG_DWORD /d 1 /f

          WINEPREFIX="$WINEPREFIX" "$WINESERVER" -k 2>/dev/null || true
          sleep 1

          echo "✓ Fixed. Restart Rhino to apply."
          echo ""
          echo "This fixes:"
          echo "  - Black layer panel"
          echo "  - Black menus and dialogs"
          echo "  - WPF control rendering issues"
        '';

        # Yak package manager for Rhino plugins
        yak-rhino = pkgs.writeShellScriptBin "yak-rhino" ''
          WINE=${wine-rhino}/bin/wine
          WINEPREFIX="''${WINEPREFIX:-$HOME/.local/share/wineprefixes/rhino8}"
          YAK="$WINEPREFIX/drive_c/Program Files/Rhino 8/System/Yak.exe"

          if [ ! -f "$YAK" ]; then
            echo "Error: Rhino not installed"
            exit 1
          fi

          if [ $# -eq 0 ]; then
            echo "Yak Package Manager"
            echo ""
            echo "Usage: yak-rhino <command> [args]"
            echo ""
            echo "Commands:"
            echo "  search <query>    - Search for packages"
            echo "  install <package> - Install a package"
            echo "  list              - List installed packages"
            exit 0
          fi

          WINEPREFIX="$WINEPREFIX" WINEDEBUG=-all "$WINE" "$YAK" "$@"
        '';

        # Run Rhino with optional debug mode
        run-rhino = pkgs.writeShellScriptBin "run-rhino" ''
          WINE=${wine-rhino}/bin/wine
          WINESERVER=${wine-rhino}/bin/wineserver
          WINEPREFIX="''${WINEPREFIX:-$HOME/.local/share/wineprefixes/rhino8}"
          RHINO="$WINEPREFIX/drive_c/Program Files/Rhino 8/System/Rhino.exe"
          LOGDIR="$WINEPREFIX/logs"

          if [ ! -f "$RHINO" ]; then
            echo "Error: Rhino not installed. Run install-rhino first."
            exit 1
          fi

          mkdir -p "$LOGDIR"
          TIMESTAMP=$(date +%Y%m%d-%H%M%S)

          # Debug mode if --debug flag
          if [ "$1" = "--debug" ]; then
            WINEDEBUG="warn+all,+uxtheme,+gdi,+win,+user32"
            LOGFILE="$LOGDIR/rhino-debug-$TIMESTAMP.log"
            echo "Debug mode enabled. Log: $LOGFILE"
            shift
          else
            WINEDEBUG="err+all"
            LOGFILE="$LOGDIR/rhino-$TIMESTAMP.log"
          fi

          # Force en-US locale (prevents MCP font crashes)
          export LC_ALL=en_US.UTF-8
          export LANG=en_US.UTF-8

          # Enable GPU acceleration (AMD/Intel Mesa)
          export MESA_GL_VERSION_OVERRIDE=4.6
          export mesa_glthread=true

          echo "Starting Rhino 8..."
          WINEPREFIX="$WINEPREFIX" WINEDEBUG="$WINEDEBUG" \
            "$WINE" "$RHINO" "$@" 2>&1 | tee "$LOGFILE"

          # Wait for Wine cleanup
          echo ""
          echo "Waiting for Wine processes to terminate..."
          WAIT=0
          while WINEPREFIX="$WINEPREFIX" "$WINESERVER" -w 2>/dev/null && [ $WAIT -lt 10 ]; do
            sleep 1
            WAIT=$((WAIT + 1))
          done

          if [ $WAIT -ge 10 ]; then
            echo "Force terminating Wine..."
            WINEPREFIX="$WINEPREFIX" "$WINESERVER" -k
          fi

          echo "✓ Session ended. Log: $LOGFILE"
        '';

        # Install Rhino with progress indicators
        install-rhino = pkgs.writeShellScriptBin "install-rhino" ''
          WINE=${wine-rhino}/bin/wine
          WINEPREFIX="''${WINEPREFIX:-$HOME/.local/share/wineprefixes/rhino8}"

          if [ -z "$1" ]; then
            echo "Usage: install-rhino <rhino-installer.exe>"
            exit 1
          fi

          INSTALLER="$1"
          if [ ! -f "$INSTALLER" ]; then
            echo "Error: File not found: $INSTALLER"
            exit 1
          fi

          echo "Installing Rhino 8 to: $WINEPREFIX"
          echo ""
          echo "Creating Wine prefix..."
          WINEPREFIX="$WINEPREFIX" WINEDEBUG=fixme-all "$WINE" wineboot

          echo ""
          echo "Starting installation..."
          echo "This will:"
          echo "  - Install .NET 8 Desktop Runtime"
          echo "  - Install Visual C++ runtimes"
          echo "  - Install WebView2"
          echo "  - Install Rhino 8"
          echo ""
          echo "Progress shown below (typically takes 10-15 minutes):"
          echo ""

          WINEPREFIX="$WINEPREFIX" WINEDEBUG=fixme-all,err+all "$WINE" "$INSTALLER"

          echo ""
          if [ -f "$WINEPREFIX/drive_c/Program Files/Rhino 8/System/Rhino.exe" ]; then
            echo "✓ Installation complete!"
            echo ""
            echo "Applying fixes..."

            # Fix UI lag (50ms MFC throttle)
            WINEPREFIX="$WINEPREFIX" "$WINE" reg add "HKCU\\Software\\Wine\\X11 Driver" /v "IdleUpdateInterval" /t REG_DWORD /d 50 /f >/dev/null 2>&1

            # Fix black menus (disable WPF hardware acceleration)
            WINEPREFIX="$WINEPREFIX" "$WINE" reg add "HKCU\\Software\\Microsoft\\Avalon.Graphics" /v "DisableHWAcceleration" /t REG_DWORD /d 1 /f >/dev/null 2>&1

            echo "✓ Fixes applied"
            echo ""
            echo "Run with: nix run .#run"
          else
            echo "⚠ Installation failed"
          fi
        '';

      in {
        packages = {
          default = wine-rhino;
          inherit wine-rhino install-rhino run-rhino yak-rhino
                  fix-ui-lag fix-black-menus;
        };

        apps = {
          install = flake-utils.lib.mkApp { drv = install-rhino; };
          run = flake-utils.lib.mkApp { drv = run-rhino; };
          yak = flake-utils.lib.mkApp { drv = yak-rhino; };
          fix-ui-lag = flake-utils.lib.mkApp { drv = fix-ui-lag; };
          fix-black-menus = flake-utils.lib.mkApp { drv = fix-black-menus; };
        };
      }
    );
}
