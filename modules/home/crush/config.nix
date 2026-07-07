{ userConfig, ... }:

{
  home-manager.users.${userConfig.username}.home.file.".config/crush/crush.json".source = ./config.json;
}
