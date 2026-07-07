{ userConfig, ... }:

{
  home-manager.users.${userConfig.username}.programs.obs-studio = {
    enable = true;
  };
}
