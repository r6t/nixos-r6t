{ lib, config, ... }: {

  options = {
    mine.flatpak.picard.enable =
      lib.mkEnableOption "enable musicbrainz picard via flatpak";
  };

  config = lib.mkIf config.mine.flatpak.picard.enable {
    services.flatpak.enable = true;
    services.flatpak.packages = [
      { appId = "org.musicbrainz.Picard"; origin = "flathub"; }
    ];
  };
}
