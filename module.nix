{ config, lib, pkgs, inputs ? {}, ... }:

with lib;

let
  cfg = config.programs.rhino8;

  # Get the rhino8-wine flake from inputs
  # This is passed via extraSpecialArgs in home-manager flake
  rhino8-wine = inputs.rhino8-wine or (throw ''
    rhino8-wine input not found!

    Add to your home-manager flake.nix inputs:
      rhino8-wine = {
        url = "github:timlupt/rhino8-wine";
        inputs.nixpkgs.follows = "nixpkgs";
      };
  '');

in {
  options.programs.rhino8 = {
    enable = mkEnableOption "Rhino 8 via Wine";

    package = mkOption {
      type = types.package;
      default = rhino8-wine.packages.${pkgs.system}.rhino8;
      description = "The rhino8 package to use";
    };

    desktopIntegration = mkOption {
      type = types.bool;
      default = true;
      description = "Create desktop entry for Rhino 8";
    };

    installTools = mkOption {
      type = types.bool;
      default = true;
      description = "Install additional tools (yak, install, uninstall, analyze-crash)";
    };
  };

  config = mkIf cfg.enable {
    # Install rhino8 command and optional tools
    home.packages = with rhino8-wine.packages.${pkgs.system};
      [ rhino8 ]
      ++ optionals cfg.installTools [
        rhino8-install
        rhino8-uninstall
        rhino8-sync
        yak
        rhino8-analyze-crash
      ];

    # Desktop integration
    xdg.desktopEntries = mkIf cfg.desktopIntegration {
      rhino8 = {
        name = "Rhino 8";
        genericName = "3D CAD";
        comment = "Rhinoceros 3D modeling via Wine";
        exec = "rhino8";
        terminal = false;
        icon = "7D24_Rhino.0";
        categories = [ "Graphics" "3DGraphics" "Engineering" ];
        mimeType = [ "application/x-rhino" ];
        startupNotify = true;
        settings = {
          StartupWMClass = "rhino.exe";
          Keywords = "3D;CAD;modeling;design;NURBS;";
        };
      };
    };
  };
}
