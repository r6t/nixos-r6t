{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.virt-viewer.enable =
        lib.mkEnableOption "enable virt-viewer in home-manager";
    };

    config = lib.mkIf config.mine.home.virt-viewer.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ virt-viewer ];
    };
}