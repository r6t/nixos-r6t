{ lib, config, ... }: {

  options = {
    mine.flatpak.calibre.enable =
      lib.mkEnableOption "enable calibre via flatpak";
  };

  config = lib.mkIf config.mine.flatpak.calibre.enable {
    services.flatpak.enable = true;
    services.flatpak.packages = [
      { appId = "com.calibre_ebook.calibre"; origin = "flathub"; }
    ];
  };
}
