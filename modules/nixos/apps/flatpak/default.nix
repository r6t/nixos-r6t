{ lib, config, ... }: { 

    options = {
      mine.flatpak.enable =
        lib.mkEnableOption "enable flatpak";
    };

    config = lib.mkIf config.mine.flatpak.enable { 
      services.flatpak.enable = true;
    };
}