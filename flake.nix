{
  description = "Rhino 8 on Linux via Wine with fixes";

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
          else
            echo "⚠ Installation may have failed. Check logs."
          fi
        '';

      in {
        packages = {
          default = wine-rhino;
          inherit wine-rhino install-rhino run-rhino yak-rhino;
        };

        apps = {
          install = flake-utils.lib.mkApp { drv = install-rhino; };
          run = flake-utils.lib.mkApp { drv = run-rhino; };
          yak = flake-utils.lib.mkApp { drv = yak-rhino; };
        };
      }
    );
}
