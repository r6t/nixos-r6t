{ lib, config, ... }: { 

    options = {
      mine.home.atuin.enable =
        lib.mkEnableOption "enable atuin in home-manager";
    };

    config = lib.mkIf config.mine.home.atuin.enable { 
      home-manager.users.r6t.programs.atuin = {
        enable = true;
        enableFishIntegration = true;
        # settings = {};
      };
    };
}
