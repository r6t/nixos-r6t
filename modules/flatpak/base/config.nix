{
  services.flatpak.enable = true;
  services.flatpak.overrides = {
    global = {
      Context.filesystems = [
        "/run/current-system/sw/share/X11/fonts:ro"
        "xdg-config/fontconfig:ro"
        "xdg-data/fonts:ro"
      ];
    };
  };
}
