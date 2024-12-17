{ lib, config, ... }: { 

    options = {
      mine.flatpak.proton-mail.enable =
        lib.mkEnableOption "enable proton-mail via flatpak";
    };

    config = lib.mkIf config.mine.flatpak.proton-mail.enable { 
      services.flatpak.enable = true;
      services.flatpak.packages = [
        { appId = "me.proton.Mail"; origin = "flathub";  }
      ];
    };
}
