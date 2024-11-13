{ lib, config, pkgs, ... }:

let
  cfg = config.mine.home.drawio;
in
{
  options.mine.home.drawio = {
    enable = lib.mkEnableOption "drawio";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.r6t = {
      home.packages = with pkgs; [ drawio ];
    };
  };
}
