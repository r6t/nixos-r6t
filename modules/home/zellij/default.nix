{ lib, config, pkgs, userConfig, isNixOS ? true, ... }:

let
  cfg = config.mine.home.zellij;
in
{
  imports = [ ./options.nix ];

  config = lib.mkIf cfg.enable (import ./config.nix {
    inherit pkgs userConfig isNixOS;
    inherit (cfg) hostSlug;
  });
}
