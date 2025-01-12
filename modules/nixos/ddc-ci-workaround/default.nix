{ lib, config, ... }: {

  options = {
    mine.ddc-ci-workaround.enable =
      lib.mkEnableOption "enable ddc-ci-workaround to get plasma 6 external display controls working again. was working until 6.2";
  };

  config = lib.mkIf config.mine.ddc-ci-workaround.enable {
    boot.kernelModules = [ "i2c-dev" "ddcci_backlight" ];
    boot.extraModulePackages = [ config.boot.kernelPackages.ddcci-driver ];
    hardware.i2c.enable = true;
    users.users.r6t.extraGroups = [ "i2c" ];
    services.udev.extraRules = ''
      KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660"
    '';
  };
}
