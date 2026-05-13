{ pkgs, ... }:

{
  imports = [
    ./lib/base.nix
    ./lib/mullvad-dns.nix
  ];

  networking.hostName = "searxng";

  services = {
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
          # Allow the JSON result format alongside the default HTML. Required by
          # Open WebUI's web search integration — without `json` here, queries
          # like /search?q=foo&format=json return HTTP 403. The instance is
          # behind caddy + (eventually) auth, so exposing the JSON API does not
          # broaden trust beyond what the web UI already provides.
          formats = [ "html" "json" ];
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
