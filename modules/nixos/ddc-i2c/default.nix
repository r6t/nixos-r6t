{ lib, config, ... }: {

  options = {
    mine.ddc-i2c.enable =
      lib.mkEnableOption "enable display control stuff";
  };

  config = lib.mkIf config.mine.ddc-i2c.enable {
    boot.kernelModules = [ "i2c-dev" "ddcci_backlight" ];
    hardware.i2c.enable = true;
    users.users.r6t.extraGroups = [ "i2c" ];
    services.udev.extraRules = ''
      KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660", TAG+="uaccess"
    '';
  };
}
