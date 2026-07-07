{ pkgs, userConfig, ... }:

{
  environment.systemPackages = with pkgs; [
    libimobiledevice
    ifuse
    usbmuxd
  ];
  services.usbmuxd.enable = true;
  users.users.${userConfig.username}.extraGroups = [ "usbmux" ];
}
