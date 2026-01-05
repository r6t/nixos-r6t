{ pkgs, ... }:

{
  imports = [
    ./r6-lxc-base.nix
    ./r6-lxc-mullvad-dns-add-on.nix
  ];

  networking.hostName = "searxng";

  services = {
    # DNS overrides for local resolution
    dnsmasq = {
      settings = {
        address = [
          "/grafana.r6t.io/192.168.6.1"
          "/r6t.io/192.168.6.10"
        ];
      };
    };

    # services.searx uses searxng package
    searx = {
      enable = true;
      package = pkgs.searxng;
      redisCreateLocally = true;
      configureUwsgi = true;

      uwsgiConfig = {
        http = "0.0.0.0:8085";
        chmod-socket = "660";
        disable-logging = true;
      };

      settings = {
        server = {
          secret_key = "@SEARXNG_SECRET@";
          base_url = "https://searxng.r6t.io";
        };
        search = {
          autocomplete = "duckduckgo";
        };
      };

      # Secret key substituted from environment file
      environmentFile = "/var/lib/searxng/env";
    };
  };

  # Ensure env file directory exists
  systemd.tmpfiles.rules = [
    "d /var/lib/searxng 0750 searx searx -"
  ];

  networking.firewall.allowedTCPPorts = [ 8085 ];
}
