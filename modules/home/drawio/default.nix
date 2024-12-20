{ lib, config, pkgs, userConfig, ... }:

let
  cfg = config.mine.home.drawio;
in
{
  options.mine.home.drawio = {
    enable = lib.mkEnableOption "drawio";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${userConfig.username} = {
      home.packages = with pkgs; [ drawio ];
    };
  };
}
