{
  imports = [
    ./lib/base.nix
    ./lib/mullvad-dns.nix
  ];

  networking.hostName = "jellyfin";

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

    # Docker mounted /mnt/crownstore/config/jellyfin to /config
    # NixOS jellyfin creates data/ subdir inside dataDir
    # So dataDir=/var/lib/jellyfin results in DB at /var/lib/jellyfin/data/jellyfin.db
    # which maps to /mnt/crownstore/config/jellyfin/data/jellyfin.db - correct!
    dataDir = "/var/lib/jellyfin";
    configDir = "/var/lib/jellyfin/config";
    cacheDir = "/var/cache/jellyfin";
    logDir = "/var/lib/jellyfin/log";
  };

  # Existing config has Docker paths hardcoded - symlink for compatibility
  # Docker used /config as root, NixOS uses /var/lib/jellyfin
  systemd.tmpfiles.rules = [
    "L /cache - - - - /var/cache/jellyfin"
    "L /config - - - - /var/lib/jellyfin"
  ];
}
