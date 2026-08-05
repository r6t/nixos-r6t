{
  imports = [
    ./lib/base.nix
    ./lib/mullvad-dns.nix
    ../modules/nixos/immich/config.nix
  ];

  networking.hostName = "immich";
}
