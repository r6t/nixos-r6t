{ lib, config, ... }:

let
  wiredIfc = "enp89s0";
in
{
  options = {
    mine.bridge.enable =
      lib.mkEnableOption "enable moon network bridge";
  };

  config = lib.mkIf config.mine.bridge.enable { };
}
