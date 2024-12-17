{ lib, config, ... }: { 

    options = {
      mine.flatpak.zoom.enable =
        lib.mkEnableOption "enable zoom via flatpak";
    };

    config = lib.mkIf config.mine.flatpak.zoom.enable { 
      services.flatpak.packages = [
        { appId = "us.zoom.Zoom"; origin = "flathub";  }
      ];
    };
}
