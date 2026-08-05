{ lib, config, userConfig, isNixOS ? true, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.home.atuin.enable (import ./config.nix { inherit userConfig isNixOS; });
}
