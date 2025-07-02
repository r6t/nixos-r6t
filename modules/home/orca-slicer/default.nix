{ lib, config, pkgs, userConfig, ... }: {

  options = {
    mine.home.orca-slicer.enable =
      lib.mkEnableOption "enable orca-slicer 3D printing in home-manager";
  };

  config = lib.mkIf config.mine.home.orca-slicer.enable {
    home-manager.users.${userConfig.username}.home.packages = with pkgs; [ orca-slicer ];
  };
}
