{ lib, config, pkgs, ... }: {

  options = {
    mine.bootloader.enable =
      lib.mkEnableOption "configure bootloader";
  };

  config = lib.mkIf config.mine.bootloader.enable {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot";
    };
    environment.systemPackages = with pkgs; [ refind ];
  };
}
