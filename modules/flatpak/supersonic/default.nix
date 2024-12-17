{ lib, config, ... }: { 

    options = {
      mine.flatpak.supersonic.enable =
        lib.mkEnableOption "enable supersonic jellyfin music client via flatpak";
    };

    config = lib.mkIf config.mine.flatpak.supersonic.enable { 
      services.flatpak.enable = true;
      services.flatpak.packages = [
        { appId = "io.github.dweymouth.supersonic"; origin = "flathub";  }
      ];
    };
}
