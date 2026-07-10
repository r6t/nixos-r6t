{ lib, config, pkgs, userConfig, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.incus.enable (
    import ./config.nix { inherit lib config pkgs userConfig; }
  );
}
