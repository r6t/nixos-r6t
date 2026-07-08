{
  services.flatpak.enable = true;
  services.flatpak.overrides = {
    global = {
      Context.filesystems = [
        "/run/current-system/sw/share/X11/fonts:ro"
        "xdg-data/fonts:ro"
      ];
    };
  };
}
