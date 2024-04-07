{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.librewolf.enable =
        lib.mkEnableOption "enable librewolf in home-manager";
    };

    config = lib.mkIf config.mine.home.librewolf.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ librewolf ];
    };
}