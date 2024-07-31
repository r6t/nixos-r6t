{ lib, config, pkgs, ... }:

let
  cfg = config.mine.home.darktable;
in
{
  options.mine.home.darktable = {
    enable = lib.mkEnableOption "enable darktable in home-manager";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.r6t = {
      # home.packages = with pkgs; [ darktable ];

      # xdg.configFile."darktable/darktablerc".source = dotfiles/${config.networking.hostName}.darktablerc;
    };
  };
}
