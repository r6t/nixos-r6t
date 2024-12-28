{ lib, config, pkgs, userConfig, ... }: {

  options = {
    mine.home.awscdk.enable =
      lib.mkEnableOption "enable aws cdk in home-manager";
  };

  config = lib.mkIf config.mine.home.awscdk.enable {
    home-manager.users.${userConfig.username}.home.packages = with pkgs; [
      nodePackages_latest.aws-cdk
    ];
  };
}
