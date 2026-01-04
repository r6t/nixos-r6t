{
  imports = [
    ./r6-lxc-base.nix
    ./r6-lxc-mullvad-dns-add-on.nix
  ];

  networking.hostName = "jellyfin";

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

  # UID 1000:100 matches existing data ownership (r6t:users on host)
  users.users.jellyfin = {
    uid = 1000;
    group = "users";
    isSystemUser = true;
    home = "/var/lib/jellyfin";
  };

  services.jellyfin = {
    enable = true;
    user = "jellyfin";
    group = "users";
    openFirewall = true;

    # Match Docker layout: /mnt/crownstore/config/jellyfin mounted to /var/lib/jellyfin
    # Contains: config/, data/, log/, metadata/, plugins/, root/, transcodes/
    dataDir = "/var/lib/jellyfin/data";
    configDir = "/var/lib/jellyfin/config";
    cacheDir = "/var/cache/jellyfin";
    logDir = "/var/lib/jellyfin/log";
  };
}
