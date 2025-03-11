{ lib, config, ... }: {

  options = {
    mine.ssh.enable =
      lib.mkEnableOption "enable and configure ssh, explicitly open 22/tcp";
  };

  config = lib.mkIf config.mine.ssh.enable {
    programs.fuse.userAllowOther = true;
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
