{ lib, config, pkgs, userConfig, ... }: {

  options = {
    mine.home.certbot.enable =
      lib.mkEnableOption "enable certbot in home-manager";
  };

  config = lib.mkIf config.mine.home.certbot.enable {
    home-manager.users.${userConfig.username}.home.packages = with pkgs; [
      certbot2
      ssm-session-manager-plugin
    ];
  };
}
