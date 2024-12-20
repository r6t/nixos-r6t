{ lib, config, pkgs, userConfig, ... }:

let
  cfg = config.mine.home.darktable;
in
{
  options.mine.home.darktable = {
    enable = lib.mkEnableOption "darktable";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${userConfig.username} = {
      home.packages = with pkgs; [ darktable ];
      xdg.configFile."darktable/darktablerc".source = dotfiles/${config.networking.hostName}.darktablerc;
    };
  };
}
