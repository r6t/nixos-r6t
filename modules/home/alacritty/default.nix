{ lib, config, pkgs, userConfig, isNixOS ? true, ... }:

let
  cfg = config.mine.home.alacritty;
in
{
  options.mine.home.alacritty.enable =
    lib.mkEnableOption "enable alacritty in home-manager";

  config = lib.mkIf cfg.enable (import ./config.nix { inherit pkgs userConfig isNixOS; });
}
