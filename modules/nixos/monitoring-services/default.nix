{ lib, config, pkgs, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.monitoring-services.enable (
    import ./config.nix { inherit lib config pkgs; }
  );
}
