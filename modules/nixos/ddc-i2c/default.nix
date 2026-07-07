{ lib, config, pkgs, ... }:

{

  options = {
    mine.ddc-i2c.enable =
      lib.mkEnableOption "enable display control stuff";
  };

  config = lib.mkIf config.mine.ddc-i2c.enable (import ./config.nix { inherit config pkgs; });
}
