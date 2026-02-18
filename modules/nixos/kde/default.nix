{ lib, config, pkgs, ... }: {

  options = {
    mine.kde.enable =
      lib.mkEnableOption "enable and configure kde desktop";
    mine.kde.tablet =
      lib.mkEnableOption "on-screen keyboard support for tablet/detachable use";
  };

  config = lib.mkIf config.mine.kde.enable {
    environment.systemPackages = with pkgs; [
      aha
      clinfo
      mesa-demos
      vulkan-tools
      wayland-utils
      wl-clipboard
    ];
    environment.plasma6.excludePackages = with pkgs.kdePackages; [
      dolphin
      dolphin-plugins
    ];
    programs.dconf.enable = true;
    services = {
      desktopManager.plasma6 = {
        enable = true;
      };
      displayManager = {
        defaultSession = "plasma";
        sddm = {
          enable = true;
          wayland.enable = true;
          # On-screen keyboard at login (tablet/detached keyboard use)
          settings.General.InputMethod =
            lib.mkIf config.mine.kde.tablet "qtvirtualkeyboard";
        };
      };
      xserver = {
        enable = true;
        xkb = {
          layout = "us";
          variant = "";
        };
      };
    };
  };
}

