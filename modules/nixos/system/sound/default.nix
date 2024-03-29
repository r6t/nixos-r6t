{ lib, config, ... }: { 

    options = {
      mine.sound.enable =
        lib.mkEnableOption "enable my audio";
    };

    config = lib.mkIf config.mine.sound.enable { 
        
      security.rtkit.enable = true;

      services.pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
        jack.enable = true;
      };

      sound.enable = true;
    };
}