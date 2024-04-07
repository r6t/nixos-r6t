{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.virt-manager.enable =
        lib.mkEnableOption "enable virt-manager in home-manager";
    };

    config = lib.mkIf config.mine.home.virt-manager.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ virt-manager ];
    };
}