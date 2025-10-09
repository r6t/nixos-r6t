{ lib, config, pkgs, userConfig, ... }:

let
  cfg = config.mine.home.darktable;
in
{
  options.mine.home.darktable = {
    enable = lib.mkEnableOption "darktable";
  };
  # version controlling darktable config prevents automatic changes with app updates
  # stopped using versioned app config Oct 2025

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      home-manager.users.${userConfig.username} = {
        home.packages = with pkgs; [
          darktable
          # sqlite3 for darktable maintenance scripts
          sqlite-interactive
        ];
      };
    })

    (lib.mkIf (cfg.enable && config.networking.hostName == "mountainball") {
      hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [
          mesa.opencl # RusticL OpenCL for AMD
        ];
      };

      environment.variables = {
        RUSTICL_ENABLE = "radeonsi";
      };

      home-manager.users.${userConfig.username} = {
        home.packages = with pkgs; [
          clinfo
        ];
      };
    })
  ];
}
