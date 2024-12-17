{ lib, config, ... }: { 

    options = {
      mine.flatpak.retroarch.enable =
        lib.mkEnableOption "enable retroarch via flatpak";
    };

    config = lib.mkIf config.mine.flatpak.retroarch.enable { 
      services.flatpak.enable = true;
      services.flatpak.packages = [
        { appId = "org.libretro.RetroArch"; origin = "flathub";  }
      ];
    };
}
