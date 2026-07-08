{ lib, config, pkgs, ... }:
{
  config = {
    environment.systemPackages = with pkgs;
      [
        aha
        clinfo
        mesa-demos
        vulkan-tools
        wayland-utils
        wl-clipboard
      ]
      ++ lib.optionals config.mine.kde.tablet [
        maliit-framework # Wayland on-screen keyboard framework
        maliit-keyboard # Wayland on-screen keyboard for Plasma
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
