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

      in {
        packages.default = wine-rhino;
        packages.wine-rhino = wine-rhino;
      }
    );
}
