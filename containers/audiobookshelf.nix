{ ... }:

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

  services.audiobookshelf = {
    enable = true;
    host = "0.0.0.0";
    port = 13378;
    user = "audiobookshelf";
    group = "users";
    openFirewall = true;
  };

  # Prevent StateDirectory from creating config/metadata dirs - Incus mounts them
  systemd.services.audiobookshelf.serviceConfig.StateDirectory = "";
}
