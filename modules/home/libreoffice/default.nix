{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.libreoffice.enable =
        lib.mkEnableOption "enable libreoffice";
    };

    config = lib.mkIf config.mine.home.libreoffice.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [
        libreoffice-qt6-fresh
      ];
    };
}
