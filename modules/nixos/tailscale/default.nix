{ lib, config, pkgs, ... }:
{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.tailscale.enable
    (import ./config.nix {
      inherit lib config pkgs;
    }).config;
}
