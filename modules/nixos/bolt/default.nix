{ lib, config, pkgs, ... }:

{

  options = {
    mine.bolt.enable =
      lib.mkEnableOption "enable thunderbolt + boltctl";
  };

  config = lib.mkIf config.mine.bolt.enable (import ./config.nix { inherit pkgs; });
}
