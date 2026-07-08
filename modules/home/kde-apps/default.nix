{ lib, config, pkgs, userConfig, ... }:

{
  options.mine.home.kde-apps = {
    enable = lib.mkEnableOption "enable plasma-manager and misc KDE software in home-manager";
    tablet = lib.mkEnableOption "tablet/touchscreen support (on-screen keyboard, touch-friendly input)";
    xwaylandScale = lib.mkOption {
      type = lib.types.number;
      default = 2;
      description = "Xwayland HiDPI scale factor (kwinrc Xwayland.Scale). Default 2 for 4K displays; set to 1.5 for 1600p displays.";
    };
    llamaCppLauncher = lib.mkEnableOption ''
      Run a StatusNotifierItem (SNI) tray daemon for the llama-cpp systemd service.
      Appears in the KDE system tray alongside wifi/bluetooth/volume. Left-click
      toggles the service; icon and tooltip reflect live service state.
      Requires mine.llama-cpp.enable on the host (polkit rule for wheel group).
    '';
  };

  config = lib.mkIf config.mine.home.kde-apps.enable
    (import ./config.nix {
      inherit lib config pkgs userConfig;
    }).config;
}
