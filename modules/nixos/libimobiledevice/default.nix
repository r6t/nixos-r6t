{ lib, config, pkgs, userConfig, ... }: {

  options = {
    mine.libimobiledevice.enable =
      lib.mkEnableOption "enable libimobiledevice iOS tools";
  };

  config = lib.mkIf config.mine.libimobiledevice.enable {
    environment.systemPackages = with pkgs; [
      libimobiledevice
      ifuse
      usbmuxd
    ];
    services.usbmuxd.enable = true;
    users.users.${userConfig.username}.extraGroups = [ "usbmux" ];
  };
}
