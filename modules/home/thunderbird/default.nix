{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.thunderbird.enable =
        lib.mkEnableOption "enable thunderbird in home-manager";
    };

    config = lib.mkIf config.mine.home.thunderbird.enable { 
      home-manager.users.r6t.programs.thunderbird = {
        enable = true;
        package = pkgs.thunderbird;
        profiles.r6t = {
          isDefault = true;
        };
      };
    };
}