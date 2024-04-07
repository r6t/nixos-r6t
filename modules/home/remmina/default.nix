{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.remmina.enable =
        lib.mkEnableOption "enable remmina in home-manager";
    };

    config = lib.mkIf config.mine.home.remmina.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ remmina ];
    };
}