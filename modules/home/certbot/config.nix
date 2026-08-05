{ pkgs, userConfig, ... }:

{
  home-manager.users.${userConfig.username}.home.packages = with pkgs; [
    certbot2
    ssm-session-manager-plugin
  ];
}
