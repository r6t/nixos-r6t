{ lib, config, pkgs, ... }:
let
  cfg = config.mine.gnome;
in
{

  options = {
    mine.gnome.enable =
      lib.mkEnableOption "enable and configure GNOME desktop";
    mine.gnome.tablet =
      lib.mkEnableOption "tablet/touchscreen extras (screen rotation, on-screen keyboard at GDM)";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      adwaita-icon-theme # cursor and icon fallback theme
      wl-clipboard
      gnome-tweaks
      gnomeExtensions.appindicator # system tray icon support
    ];

    # GNOME Keyring: stores NetworkManager WiFi passwords, GPG/SSH keys, etc.
    # Without this, NM has no secret agent and re-prompts for WiFi on every boot.
    services.gnome.gnome-keyring.enable = true;
    security.pam.services.gdm-password.enableGnomeKeyring = true;

    # Exclude default GNOME apps we don't need
    services.gnome.core-apps.enable = false;
    environment.gnome.excludePackages = with pkgs; [
      gnome-tour
      gnome-user-docs
    ];

    # iio-sensor-proxy for automatic screen rotation (handheld/tablet only)
    hardware.sensor.iio.enable = cfg.tablet;

    programs.dconf.enable = true;

    # Qt apps look consistent with GNOME's Adwaita style
    qt = {
      enable = true;
      platformTheme = "gnome";
      style = "adwaita-dark";
    };

    services = {
      desktopManager.gnome.enable = true;
      displayManager = {
        gdm = {
          enable = true;
          wayland = true;
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
