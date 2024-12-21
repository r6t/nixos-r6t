{ lib, config, ... }: {

  options = {
    mine.flatpak.libreoffice.enable =
      lib.mkEnableOption "enable libreoffice via flatpak";
  };

  config = lib.mkIf config.mine.flatpak.libreoffice.enable {
    services.flatpak.packages = [
      { appId = "org.libreoffice.LibreOffice"; origin = "flathub"; }
    ];
  };
}
