{ lib, config, pkgs, userConfig, isNixOS ? true, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.home.git.enable (
    import ./config.nix { inherit lib config pkgs userConfig isNixOS; }
  );
}
