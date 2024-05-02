{ lib, config, pkgs, ... }: { 

    options = {
      mine.steam.enable =
        lib.mkEnableOption "enable steam";
    };

    config = lib.mkIf config.mine.steam.enable { 
      environment = {
        sessionVariables = {
          STEAM_EXTRA_COMPAT_TOOLS_PATHS = "/home/r6t/.steam/root/compatibilitytools.d";
        };
        systemPackages = with pkgs; [
          "protonup-qt"
        ];
      };
      programs.gamemode.enable = true;
      programs.steam = {
        enable = true;
        gamescopeSession.enable = true;
        };
    };
}