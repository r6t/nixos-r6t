{ lib, config, ... }: { 

    options = {
      mine.ssh.enable =
        lib.mkEnableOption "enable and configure ssh";
    };

    config = lib.mkIf config.mine.ssh.enable { 
      services.openssh = {
        enable = true;
        settings = {
          PermitRootLogin = "no";
          PasswordAuthentication = false;
        };
      };
    };
}