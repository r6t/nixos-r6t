{ lib, config, pkgs, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.wg-metrics.enable (
    import ./config.nix { inherit lib config pkgs; }
  );
}
