{ lib, config, ... }: {

  options = {
    mine.flatpak.base.enable =
      lib.mkEnableOption "enable base flatpak configuration";
  };

  config = lib.mkIf config.mine.flatpak.base.enable {
    services.flatpak.enable = true;
    services.flatpak.overrides = {
      global = {
        Context.filesystems = [
          "/run/current-system/sw/share/X11/fonts:ro"
          "xdg-data/fonts:ro"
        ];
      };
    };
  };
}
