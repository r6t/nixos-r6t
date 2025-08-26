{ lib, config, ... }:

{
  options = {
    mine.bridge.enable =
      lib.mkEnableOption "enable moon network bridge";
  };

  config = lib.mkIf config.mine.bridge.enable { };
}
