{ lib, config, userConfig, isNixOS ? true, ... }:

let
  cfg = config.mine.home.atuin;
in
{
  options.mine.home.atuin.enable =
    lib.mkEnableOption "enable atuin in home-manager";

  config = lib.mkIf cfg.enable (import ./config.nix { inherit userConfig isNixOS; });
}
