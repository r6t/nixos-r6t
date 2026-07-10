{ lib, config, pkgs, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.caddy.enable (
    import ./config.nix { inherit lib config pkgs; }
  );
}
