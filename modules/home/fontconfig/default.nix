{ lib, config, userConfig, ... }: {

  options = {
    mine.home.fontconfig.enable =
      lib.mkEnableOption "enable fontconfig in home-manager";
  };

  config = lib.mkIf config.mine.home.fontconfig.enable {
    home-manager.users.${userConfig.username}.fonts = {
      fontconfig.enable = true;
    };
  };
}
