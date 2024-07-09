{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.fzf.enable =
        lib.mkEnableOption "enable fzf in home-manager";
    };

    config = lib.mkIf config.mine.home.fzf.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ fzf ];
    };
}