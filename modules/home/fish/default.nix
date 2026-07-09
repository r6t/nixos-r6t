{ lib, config, pkgs, userConfig, isNixOS ? true, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.home.fish.enable (import ./config.nix { inherit lib pkgs userConfig isNixOS; });
}
