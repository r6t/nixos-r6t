{ ... }:

{
  imports = [
    ./lib/base.nix
    ./lib/mullvad-dns.nix
  ];

  networking = {
    hostName = "gitea";
    firewall.allowedTCPPorts = [ 3000 2222 ];
  };

  services.gitea = {
    enable = true;
    appName = "r6t Git";
    database.type = "sqlite3";
    settings = {
      server = {
        DOMAIN = "git.r6t.io";
        ROOT_URL = "https://git.r6t.io/";
        HTTP_ADDR = "0.0.0.0";
        HTTP_PORT = 3000;

        START_SSH_SERVER = true;
        SSH_LISTEN_HOST = "0.0.0.0";
        SSH_LISTEN_PORT = 2222;
        SSH_DOMAIN = "ssh.git.r6t.io";
        SSH_PORT = 2222;
        BUILTIN_SSH_SERVER_USER = "git";
        SSH_USER = "git";
      };
      session.COOKIE_SECURE = true;
    };
  };
}
