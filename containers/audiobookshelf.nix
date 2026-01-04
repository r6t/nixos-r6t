{ lib, pkgs, ... }:

let
  configPath = "/var/lib/audiobookshelf/config";
  metadataPath = "/var/lib/audiobookshelf/metadata";
in
{
  imports = [
    ./r6-lxc-base.nix
    ./r6-lxc-mullvad-dns-add-on.nix
  ];

  networking.hostName = "audiobookshelf";

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

  # UID 1000 matches existing data ownership (r6t:users on host)
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

  # NixOS module bug: sets env vars that audiobookshelf ignores.
  # Must pass --config and --metadata CLI flags for correct paths.
  systemd.services.audiobookshelf.serviceConfig.ExecStart = lib.mkForce
    "${pkgs.audiobookshelf}/bin/audiobookshelf --host 0.0.0.0 --port 13378 --config ${configPath} --metadata ${metadataPath}";

  # BackupManager hardcodes /metadata and /config paths
  # regardless of CLI flags. Symlink to actual locations.
  systemd.tmpfiles.rules = [
    "L /config - - - - ${configPath}"
    "L /metadata - - - - ${metadataPath}"
  ];
}
