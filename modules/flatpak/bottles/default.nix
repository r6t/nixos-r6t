{ lib, config, ... }: {

  options = {
    mine.flatpak.bottles.enable =
      lib.mkEnableOption "enable bottles via flatpak";
  };

  config = lib.mkIf config.mine.flatpak.bottles.enable {
    services.flatpak.enable = true;
    services.flatpak.packages = [
      { appId = "com.usebottles.bottles"; origin = "flathub"; }
    ];
  };
}
