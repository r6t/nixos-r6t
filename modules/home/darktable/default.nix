{ lib, config, inputs, ... }:

let
  cfg = config.mine.home.darktable;
in
{
  options.mine.home.darktable = {
    enable = lib.mkEnableOption "darktable from nixpkgs-unstable";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.r6t = {
      home.packages = with inputs.nixpkgs-unstable.legacyPackages.x86_64-linux; [
        darktable
      ];
      # home.packages = with pkgs; [ darktable ];
      xdg.configFile."darktable/darktablerc".source = dotfiles/${config.networking.hostName}.darktablerc;
    };
  };
}
