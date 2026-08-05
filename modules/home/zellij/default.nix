{ lib, config, pkgs, userConfig, isNixOS ? true, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.home.zellij.enable (import ./config.nix { inherit pkgs userConfig isNixOS; });
}
