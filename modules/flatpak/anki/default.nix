{ lib, config, ... }: {

  options = {
    mine.flatpak.anki.enable =
      lib.mkEnableOption "enable anki via flatpak";
  };

  config = lib.mkIf config.mine.flatpak.anki.enable {
    services.flatpak.enable = true;
    services.flatpak.packages = [
      { appId = "net.ankiweb.Anki"; origin = "flathub"; }
    ];
  };
}
