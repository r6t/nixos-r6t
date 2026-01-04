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
    # Uses nixpkgs defaults:
    # dataDir = /var/lib/jellyfin
    # configDir = /var/lib/jellyfin/config
    # cacheDir = /var/cache/jellyfin
    # logDir = /var/lib/jellyfin/log
    #
    # Incus profile mounts:
    # /mnt/crownstore/config/jellyfin/data   -> /var/lib/jellyfin
    # /mnt/crownstore/config/jellyfin/config -> /var/lib/jellyfin/config
    # /mnt/crownstore/config/jellyfin/log    -> /var/lib/jellyfin/log
    # /mnt/crownstore/cache/jellyfin         -> /var/cache/jellyfin
  };
}
