{
  description = "Rhino 8 on Linux via Wine";

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

        # Helper to create a script with environment
        mkScript = name: script: pkgs.writeShellScriptBin name ''
          export RHINO_SCRIPTS="${./scripts}"
          export RHINO_FIXES="${./fixes}"
          export RHINO_CONFIG="${./default-config.toml}"
          export PATH="${wine-rhino}/bin:${pkgs.nodejs}/bin:$PATH"

          ${builtins.readFile script}
        '';

      in {
        packages = {
          default = wine-rhino;
          wine-rhino = wine-rhino;

          # User-facing commands
          rhino8 = mkScript "rhino8" ./scripts/run.sh;
          rhino8-install = mkScript "rhino8-install" ./scripts/install.sh;
          rhino8-uninstall = mkScript "rhino8-uninstall" ./scripts/uninstall.sh;
          rhino8-sync = mkScript "rhino8-sync" ./scripts/apply-fix.sh;
          yak = mkScript "yak" ./scripts/yak.sh;
          rhino8-analyze-crash = mkScript "rhino8-analyze-crash" ./scripts/analyze-crash.sh;

          # Legacy names for backwards compatibility
          run-rhino = mkScript "run-rhino" ./scripts/run.sh;
          install-rhino = mkScript "install-rhino" ./scripts/install.sh;
          rhino-uninstall = mkScript "rhino-uninstall" ./scripts/uninstall.sh;
          yak-rhino = mkScript "yak-rhino" ./scripts/yak.sh;
          rhino-analyze-crash = mkScript "rhino-analyze-crash" ./scripts/analyze-crash.sh;
        };

        apps = {
          install = flake-utils.lib.mkApp { drv = self.packages.${system}.rhino8-install; };
          run = flake-utils.lib.mkApp { drv = self.packages.${system}.rhino8; };
          yak = flake-utils.lib.mkApp { drv = self.packages.${system}.yak; };
          uninstall = flake-utils.lib.mkApp { drv = self.packages.${system}.rhino8-uninstall; };
          analyze-crash = flake-utils.lib.mkApp { drv = self.packages.${system}.rhino8-analyze-crash; };
        };
      }
    ) // {
      # Home Manager module
      homeManagerModules.default = import ./module.nix;
    };
}
