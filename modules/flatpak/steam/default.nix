{ lib, config, ... }: { 

    options = {
      mine.flatpak.steam.enable =
        lib.mkEnableOption "enable steam via flatpak";
    };

    config = lib.mkIf config.mine.flatpak.steam.enable { 
      services.flatpak.packages = [
        { appId = "com.valvesoftware.Steam"; origin = "flathub";  }
      ];
    };
}
