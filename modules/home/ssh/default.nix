{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.ssh.enable =
        lib.mkEnableOption "configure ssh in home-manager";
    };

    config = lib.mkIf config.mine.home.ssh.enable { 
      home-manager.users.r6t.programs.ssh = {
        enable = true;
          matchBlocks = {
            "git-codecommit.*.amazonaws.com" = {
              user = "APKAYS2NW3CV2ZGOXWZU";
              identityFile = "/home/r6t/.ssh/cc_ryan_codecommit_rsa";
            };
          };
      };
    };
}