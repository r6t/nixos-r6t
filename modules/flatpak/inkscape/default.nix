{ lib, config, ... }: { 

    options = {
      mine.flatpak.inkscape.enable =
        lib.mkEnableOption "enable inkscape via flatpak";
    };

    config = lib.mkIf config.mine.flatpak.inkscape.enable { 
      services.flatpak.enable = true;
      services.flatpak.packages = [
        { appId = "org.inkscape.Inkscape"; origin = "flathub";  }
      ];
    };
}
