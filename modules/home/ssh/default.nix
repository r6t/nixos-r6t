{ lib, config, ... }: { 

    options = {
      mine.home.ssh.enable =
        lib.mkEnableOption "configure ssh in home-manager";
    };

    config = lib.mkIf config.mine.home.ssh.enable { 
      home-manager.users.r6t.programs.ssh = {
        enable = true;
        matchBlocks = {
          "git-codecommit.*.amazonaws.com" = {
            host = "git-codecommit.*.amazonaws.com";
            user = "APKAYS2NW3CVZZ7ZOA5Y";
            identityFile = "~/.ssh/cc_ryan_codecommit_rsa";
            extraConfig = "";
          };
        };
      };
    };
}