{ lib, config, pkgs, userConfig, ... }:

{
  options.mine.home.browsers.enable =
    lib.mkEnableOption "enable desktop web browsers in home-manager";

  config = lib.mkIf config.mine.home.browsers.enable
    (import ./config.nix {
      inherit lib config pkgs userConfig;
    }).config;
}
