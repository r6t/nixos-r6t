{ lib, config, userConfig, ... }: {

  options = {
    mine.home.ssh.enable =
      lib.mkEnableOption "configure ssh in home-manager";
  };

  config = lib.mkIf config.mine.home.ssh.enable {
    home-manager.users.${userConfig.username}.programs.ssh = {
      enable = true;
      # added 250909 to address warning - TODO lookup specifics
      enableDefaultConfig = false;
      matchBlocks = {
        "git-codecommit.*.amazonaws.com" = {
          user = "APKAYS2NW3CVZZ7ZOA5Y";
          identityFile = "/home/${userConfig.username}/.ssh/misc-keys/cc_ryan_codecommit_rsa";
        };
      };
    };
  };
}
