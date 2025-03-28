{ lib, config, ... }: {

  options = {
    mine.bluetooth.enable =
      lib.mkEnableOption "enable my usual bluetooth config";
  };

  config = lib.mkIf config.mine.bluetooth.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          # adding the 3 below trying to get bluetooth to start enabled
          Enable = "Source,Sink,Media,Socket";
          FastConnectable = "true";
          MultiProfile = "multiple";
          # Experimental settings allow the os to read bluetooth device battery level
          Experimental = true;
        };
      };
    };
  };
}
