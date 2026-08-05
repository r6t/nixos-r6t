{ lib, config, pkgs, userConfig, ... }:

let
  cfg = config.mine.home.darktable;
in

{
  config = lib.mkMerge [
    {
      home-manager.users.${userConfig.username} = {
        home.packages = with pkgs; [
          darktable
          # sqlite3 for darktable maintenance scripts
          sqlite-interactive
        ];
      };
    }

    (lib.mkIf cfg.enableRusticl {
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
