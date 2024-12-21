{ lib, config, pkgs, userConfig, ... }: {

  options = {
    mine.home.virt-viewer.enable =
      lib.mkEnableOption "enable virt-viewer in home-manager";
  };

  config = lib.mkIf config.mine.home.virt-viewer.enable {
    home-manager.users.${userConfig.username}.home.packages = with pkgs; [ virt-viewer ];
  };
}
