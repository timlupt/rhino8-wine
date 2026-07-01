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
        packages.default = wine-rhino;
        packages.wine-rhino = wine-rhino;
        packages.install-rhino = install-rhino;

        apps.install = flake-utils.lib.mkApp { drv = install-rhino; };
      }
    );
}
