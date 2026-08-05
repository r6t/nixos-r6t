{ pkgs, userConfig, ... }:

{
  home-manager.users.${userConfig.username}.home.packages = with pkgs; [ teams-for-linux ];
}
