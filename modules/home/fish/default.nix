{ lib, config, pkgs, userConfig, isNixOS ? true, ... }:

let
  cfg = config.mine.home.fish;
in
{
  options.mine.home.fish.enable =
    lib.mkEnableOption "enable fish in home-manager";

  config = lib.mkIf cfg.enable (import ./config.nix { inherit lib pkgs userConfig isNixOS; });
}
