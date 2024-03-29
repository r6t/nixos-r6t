{ lib, config, ... }: { 

    options = {
      mine.bluetooth.enable =
        lib.mkEnableOption "enable my usual bluetooth config";
    };

    config = lib.mkIf config.mine.bluetooth.enable { 
      hardware.bluetooth.enable = true;
      # Experimental settings allow the os to read bluetooth device battery level
      hardware.bluetooth.settings = {
        General = {
          Experimental = true;
         };
      };

      services.blueman.enable = true;
    };
}