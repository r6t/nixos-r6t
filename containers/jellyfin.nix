{ ... }:

{
  imports = [
    ./lib/base.nix
    ./lib/mullvad-dns.nix
    ../modules/nixos/jellyfin/default.nix
  ];

  networking.hostName = "jellyfin";

  mine.jellyfin.enable = true;
}
