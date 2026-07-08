{ lib, config, pkgs, userConfig, ... }:

{
  options.mine.home.darktable.enable = lib.mkEnableOption "darktable";

  config = lib.mkIf config.mine.home.darktable.enable
    (import ./config.nix {
      inherit lib config pkgs userConfig;
    }).config;
}
