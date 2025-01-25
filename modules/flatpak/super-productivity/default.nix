{ lib, config, ... }: {

  options = {
    mine.flatpak.super-productivity.enable =
      lib.mkEnableOption "enable super-productivity client via flatpak";
  };

  config = lib.mkIf config.mine.flatpak.super-productivity.enable {
    services.flatpak.enable = true;
    services.flatpak.packages = [
      { appId = "com.super_productivity.SuperProductivity"; origin = "flathub"; }
    ];
  };
}
