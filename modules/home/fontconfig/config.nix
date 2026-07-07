{ userConfig, ... }:

{
  home-manager.users.${userConfig.username}.fonts = {
    fontconfig.enable = true;
  };
}
