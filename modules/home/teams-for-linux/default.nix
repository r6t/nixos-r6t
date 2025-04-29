{ lib, config, pkgs, userConfig, ... }: {

  options = {
    mine.home.teams-for-linux.enable =
      lib.mkEnableOption "enable teams-for-linux in home-manager";
  };

  config = lib.mkIf config.mine.home.teams-for-linux.enable {
    home-manager.users.${userConfig.username}.home.packages = with pkgs; [ teams-for-linux ];
  };
}
