{ lib, config, pkgs, ... }:
let
  cfg = config.mine.kde;
in
{

  options = {
    mine.kde.enable =
      lib.mkEnableOption "enable and configure kde desktop";
    mine.kde.tablet =
      lib.mkEnableOption "tablet/touchscreen extras (on-screen keyboard packages)";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      [
        aha
        clinfo
        mesa-demos
        vulkan-tools
        wayland-utils
        wl-clipboard
      ]
      ++ lib.optionals cfg.tablet [
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

