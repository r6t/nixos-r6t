{ lib, config, pkgs, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.exit-node-routing.enable (
    import ./config.nix { inherit lib config pkgs; }
  );
}
