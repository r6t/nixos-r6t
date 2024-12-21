{ lib, config, ... }: {

  options = {
    mine.flatpak.protonup-qt.enable =
      lib.mkEnableOption "enable protonup-qt via flatpak";
  };

  config = lib.mkIf config.mine.flatpak.protonup-qt.enable {
    services.flatpak.enable = true;
    services.flatpak.packages = [
      { appId = "net.davidotek.pupgui2"; origin = "flathub"; }
    ];
  };
}
