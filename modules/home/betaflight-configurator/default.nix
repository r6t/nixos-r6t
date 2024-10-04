{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.betaflight-configurator.enable =
        lib.mkEnableOption "enable betaflight config";
    };

    config = lib.mkIf config.mine.home.betaflight-configurator.enable { 
      # app.betaflight.com (requires chromium) web app uses newer unreleased version
      # home-manager.users.r6t.home.packages = with pkgs; [ betaflight-configurator ];

      environment.systemPackages = with pkgs; [
        dfu-util
      ];
     
      services.udev.extraRules = ''
        # All STMicroelectronics STM32 devices
        SUBSYSTEM=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="5740", MODE="0664", GROUP="plugdev"
        SUBSYSTEM=="usb", ATTRS{idVendor}=="0483", ATTRS{idProduct}=="df11", MODE="0666", GROUP="plugdev"
        # All Artery AT32 devices
        # SUBSYSTEM=="usb", ATTRS{idVendor}=="2e3c", ATTRS{idProduct}=="****", MODE="0664", GROUP="plugdev"
      '';

      systemd.services.ModemManager.enable = false;
      users.users.r6t.extraGroups = [ "plugdev" "dialout" ];

    };
}
