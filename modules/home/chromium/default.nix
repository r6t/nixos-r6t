{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.chromium.enable =
        lib.mkEnableOption "enable chromium in home-manager";
    };

    config = lib.mkIf config.mine.home.chromium.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ ungoogled-chromium ];
    };
}