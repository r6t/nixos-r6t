{ lib, config, pkgs, ... }:
let
  # Helper script for udev: register ddcci device on an I2C adapter
  # Workaround for ddcci auto-probing broken on kernel 6.8+
  ddcci-attach = pkgs.writeShellScript "ddcci-attach" ''
    sleep 2
    echo ddcci 0x37 > "/sys/$1/new_device" 2>/dev/null || true
  '';
in
{

  options = {
    mine.ddc-i2c.enable =
      lib.mkEnableOption "enable display control stuff";
  };

  config = lib.mkIf config.mine.ddc-i2c.enable {
    boot.kernelModules = [ "i2c-dev" "ddcci_backlight" ];
    boot.extraModulePackages = [ config.boot.kernelPackages.ddcci-driver ];
    hardware.i2c.enable = true;
    users.users.r6t.extraGroups = [ "i2c" ];

    # ddcutil: CLI brightness control for external monitors
    # Usage: ddcutil detect        (list monitors)
    #        ddcutil setvcp 10 70  (set brightness to 70%)
    #        ddcutil getvcp 10     (read current brightness)
    environment.systemPackages = [ pkgs.ddcutil ];

    services.udev.extraRules = ''
      KERNEL=="i2c-[0-9]*", GROUP="i2c", MODE="0660", TAG+="uaccess"

      # Workaround: ddcci auto-probing broken on kernel 6.8+
      # When an AMDGPU I2C adapter appears, register a ddcci device on it
      SUBSYSTEM=="i2c", ATTR{name}=="AMDGPU DM i2c hw bus *", ACTION=="add", RUN+="${ddcci-attach} %S%p"
    '';
  };
}
