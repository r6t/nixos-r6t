{ lib, config, pkgs, userConfig, ... }: {

  options = {
    mine.home.k2pdfopt.enable =
      lib.mkEnableOption "enable k2pdfopt in home-manager";
  };

  config = lib.mkIf config.mine.home.k2pdfopt.enable {
    home-manager.users.${userConfig.username}.home.packages = with pkgs; [ k2pdfopt ];
  };
}
