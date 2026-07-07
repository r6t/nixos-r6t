{ lib, config, ... }:

{

  options = {
    mine.bluetooth.enable =
      lib.mkEnableOption "enable my usual bluetooth config";
  };

  config = lib.mkIf config.mine.bluetooth.enable (import ./config.nix);
}
