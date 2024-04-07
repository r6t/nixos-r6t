{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.betaflight-configurator.enable =
        lib.mkEnableOption "enable betaflight-configurator in home-manager";
    };

    config = lib.mkIf config.mine.home.betaflight-configurator.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ betaflight-configurator ];
    };
}