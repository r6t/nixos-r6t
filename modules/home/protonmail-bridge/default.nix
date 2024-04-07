{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.protonmail-bridge.enable =
        lib.mkEnableOption "enable protonmail-bridge in home-manager";
    };

    config = lib.mkIf config.mine.home.protonmail-bridge.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ protonmail-bridge ];
    };
}