{ lib, config, userConfig, ... }: {

  options = {
    mine.home.obs-studio.enable =
      lib.mkEnableOption "enable obs-studio in home-manager";
  };

  config = lib.mkIf config.mine.home.obs-studio.enable {

    home-manager.users.${userConfig.username}.programs.obs-studio = {
      enable = true;
    };
  };
}
