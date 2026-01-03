{
  imports = [
    ./r6-lxc-base.nix
    ./r6-lxc-mullvad-dns-add-on.nix
  ];

  networking.hostName = "audiobookshelf";

  # audiobookshelf user with UID 1000 to match existing data ownership
  users.users.audiobookshelf = {
    uid = 1000;
    group = "users";
    isSystemUser = true;
    home = "/var/lib/audiobookshelf";
  };

  # Upstream NixOS module stores config/metadata in /var/lib/audiobookshelf
  # symlink to existing persistent storage paths mounted by Incus
  systemd.tmpfiles.rules = [
    "d /var/lib/audiobookshelf 0755 audiobookshelf users -"
    "L /var/lib/audiobookshelf/config - - - - /mnt/crownstore/config/audiobookshelf"
    "L /var/lib/audiobookshelf/metadata - - - - /mnt/crownstore/app-storage/audiobookshelf/metadata"
  ];

  services.audiobookshelf = {
    enable = true;
    host = "0.0.0.0";
    port = 13378;
    user = "audiobookshelf";
    group = "users";
    openFirewall = true;
  };
}
