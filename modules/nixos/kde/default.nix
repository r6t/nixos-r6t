{ lib, config, pkgs, ... }: {

  options = {
    mine.kde.enable =
      lib.mkEnableOption "enable and configure kde desktop";
  };

  config = lib.mkIf config.mine.kde.enable {
    environment.systemPackages = with pkgs; [
      aha
      clinfo
      glxinfo
      vulkan-tools
      wayland-utils
      wl-clipboard
    ];
    programs.dconf.enable = true;
    services = {
      desktopManager.plasma6.enable = true;
      displayManager = {
        defaultSession = "plasma";
        sddm = {
          enable = true;
          wayland.enable = true;
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

