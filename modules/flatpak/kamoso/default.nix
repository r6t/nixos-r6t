{ lib, config, ... }: {

  options = {
    mine.flatpak.kamoso.enable =
      lib.mkEnableOption "enable kamoso via flatpak";
  };

  config = lib.mkIf config.mine.flatpak.kamoso.enable {
    services.flatpak.packages = [
      { appId = "org.kde.kamoso"; origin = "flathub"; }
    ];
  };
}
