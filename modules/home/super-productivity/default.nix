{ lib, config, pkgs, userConfig, ... }: {

  options = {
    mine.home.super-productivity.enable =
      lib.mkEnableOption "super-productivity";
  };

  config = lib.mkIf config.mine.home.super-productivity.enable {
    home-manager.users.${userConfig.username}.home.packages = with pkgs; [ super-productivity ];
  };
}
