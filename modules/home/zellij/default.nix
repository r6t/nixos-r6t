{ lib, config, pkgs, userConfig, isNixOS ? true, ... }:

let
  cfg = config.mine.home.zellij;
in
{
  options.mine.home.zellij.enable =
    lib.mkEnableOption "enable zellij in home-manager";

  config = lib.mkIf cfg.enable (import ./config.nix { inherit pkgs userConfig isNixOS; });
}
