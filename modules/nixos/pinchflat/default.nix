{ lib, config, ... }:

{
  options = {
    mine.pinchflat.enable = lib.mkEnableOption "enable pinchflat";
  };

  config = lib.mkIf config.mine.pinchflat.enable (import ./config.nix { inherit lib; });
}
