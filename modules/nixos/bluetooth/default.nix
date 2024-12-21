{ lib, config, ... }: {

  options = {
    mine.bluetooth.enable =
      lib.mkEnableOption "enable my usual bluetooth config";
  };

  config = lib.mkIf config.mine.bluetooth.enable {
    hardware.bluetooth.enable = true;
    hardware.bluetooth.settings = {
      General = {
        # Experimental settings allow the os to read bluetooth device battery level
        Experimental = true;
      };
    };
  };
}
