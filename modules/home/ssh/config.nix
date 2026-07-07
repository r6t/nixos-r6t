{ userConfig, ... }:

{
  home-manager.users.${userConfig.username}.programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "git-codecommit.*.amazonaws.com" = {
        User = "APKAYS2NW3CVZZ7ZOA5Y";
        IdentityFile = "/home/${userConfig.username}/.ssh/misc-keys/cc_ryan_codecommit_rsa";
      };
    };
  };
}
