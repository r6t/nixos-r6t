{ pkgs, ... }:

{
  imports = [
    ./lib/base.nix
    ./lib/mullvad-dns.nix
    ../modules/nixos/pinchflat/default.nix
  ];

  networking.hostName = "pinchflat";

  # UID/GID match the existing mountainball service and host media ownership.
  users.users.r6t = {
    isSystemUser = true;
    uid = 1000;
    group = "users";
    home = "/var/lib/pinchflat";
  };

  mine.pinchflat = {
    enable = true;
    startAtBoot = true;
    cookieFile = "/run/pinchflat-identity/cookies.txt";
    ytDlpBaseConfigFile = "/run/pinchflat-identity/base-config.txt";
  };

  environment.systemPackages = with pkgs; [
    sqlite
    yt-dlp
  ];

  systemd.tmpfiles.rules = [
    "d /mnt 0755 root root -"
    "d /mnt/thunderbay 0755 root root -"
    "d /mnt/thunderbay/8TB-D 0755 root root -"
    "d /mnt/thunderbay/8TB-D/storage 0755 root root -"
    "d /mnt/thunderbay/8TB-D/storage/plex 0755 root root -"
  ];
}
