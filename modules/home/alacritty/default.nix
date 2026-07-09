{ lib, config, pkgs, userConfig, isNixOS ? true, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.home.alacritty.enable (import ./config.nix { inherit pkgs userConfig isNixOS; });
}
