{ lib, ... }:

{
  imports = [
    ./r6-lxc-base.nix
    ./r6-lxc-mullvad-dns-add-on.nix
  ];

  networking.hostName = "pocket-id";

  # append DNS server settings: crown DNS override
  # allows workloads not on tailnet to use same DNS names
  services = {
    dnsmasq = {
      settings = {
        address = [
          # specific overrides
          "/grafana.r6t.io/192.168.6.1"

          # wildcard so app LXCs hit router caddy
          "/r6t.io/192.168.6.10"
        ];
      };
    };
  };

  # Match existing data ownership (r6t:users = 1000:100)
  users.users.pocket-id = {
    uid = lib.mkForce 1000;
    group = "users";
    isSystemUser = true;
    home = "/var/lib/pocket-id";
  };

  services.pocket-id = {
    enable = true;
    user = "pocket-id";
    group = "users";

    # Data directory mounted by Incus from persistent storage
    dataDir = "/var/lib/pocket-id";

    settings = {
      PUBLIC_APP_URL = "https://pid.r6t.io";
      TRUST_PROXY = true;
    };
  };

  networking.firewall.allowedTCPPorts = [ 1411 ];
}
