{ lib, config, ... }: { 

    options = {
      mine.steam.enable =
        lib.mkEnableOption "enable steam";
    };

    config = lib.mkIf config.mine.steam.enable { 
      programs.steam = {
        enable = true;
        gamescopeSession.enable = true;
        };
    };
}