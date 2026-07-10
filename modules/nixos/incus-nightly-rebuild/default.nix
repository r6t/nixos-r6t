{ lib, config, pkgs, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.incus-nightly-rebuild.enable (
    import ./config.nix { inherit lib config pkgs; }
  );
}
