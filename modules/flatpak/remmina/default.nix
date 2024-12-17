{ lib, config, ... }: { 

    options = {
      mine.flatpak.remmina.enable =
        lib.mkEnableOption "enable remmina via flatpak";
    };

    config = lib.mkIf config.mine.flatpak.remmina.enable { 
      services.flatpak.packages = [
        { appId = "org.remmina.Remmina"; origin = "flathub";  }
      ];
    };
}
