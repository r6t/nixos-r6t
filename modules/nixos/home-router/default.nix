{ lib, config, pkgs, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.home-router.enable (
    import ./config.nix { inherit lib config pkgs; }
  );
}
