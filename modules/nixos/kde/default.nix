{ lib, config, pkgs, inputs, ... }: { 

    options = {
      mine.kde.enable =
        lib.mkEnableOption "enable and configure kde desktop";
    };

    config = lib.mkIf config.mine.kde.enable { 
      environment.systemPackages = with pkgs; [
      ];
      services.displayManager.sddm.enable = true;
      services.desktopManager.plasma6.enable = true;
      services.displayManager.defaultSession = "plasma-wayland";
      programs.dconf.enable = true;
      services.xserver = {
        enable = true;
        xkb = {
          layout = "us";
          variant = "";
        };
      };

    };
}