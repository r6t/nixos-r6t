{ lib, config, ... }: {

  options = {
    mine.ssh.enable =
      lib.mkEnableOption "enable and configure ssh";
  };

  config = lib.mkIf config.mine.ssh.enable {
    networking.firewall.allowedTCPPorts = [ 22 ];
    services.openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };
  };
}
