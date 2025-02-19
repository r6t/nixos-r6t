{ lib, config, ... }: {

  options = {
    mine.flatpak.element.enable =
      lib.mkEnableOption "enable element via flatpak";
  };

  config = lib.mkIf config.mine.flatpak.element.enable {
    services.flatpak.enable = true;
    services.flatpak.packages = [
      { appId = "im.riot.Riot"; origin = "flathub"; }
    ];
  };
}
