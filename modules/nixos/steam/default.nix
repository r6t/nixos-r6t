{ lib, config, pkgs, userConfig, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.steam.enable
    (import ./config.nix {
      inherit lib config pkgs userConfig;
    }).config;
}
