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
      home.packages = with pkgs; [
        darktable
        sqlite-interactive # sqlite3 required for darktable maintenance scripts
      ];
      xdg.configFile."darktable/darktablerc".source = dotfiles/${config.networking.hostName}.darktablerc;
    };
  };
}
