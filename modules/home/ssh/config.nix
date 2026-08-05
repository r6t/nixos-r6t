{ config, userConfig, ... }:

{
  home-manager.users.${userConfig.username}.programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = config.mine.home.ssh.matchBlocks;
  };
}
