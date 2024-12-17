{ lib, config, ... }: { 

    options = {
      mine.flatpak.deezer.enable =
        lib.mkEnableOption "enable deezer via flatpak";
    };

    config = lib.mkIf config.mine.flatpak.deezer.enable { 
      services.flatpak.packages = [
        { appId = "dev.aunetx.deezer"; origin = "flathub";  }
      ];
    };
}
