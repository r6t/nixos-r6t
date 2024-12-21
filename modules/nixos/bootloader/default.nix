{ lib, config, ... }: {

  options = {
    mine.bootloader.enable =
      lib.mkEnableOption "configure bootloader";
  };

  config = lib.mkIf config.mine.bootloader.enable {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
