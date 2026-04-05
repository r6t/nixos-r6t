{
  imports = [
    ./lib/base.nix
    ./lib/mullvad-dns.nix
    ../modules/nixos/immich/default.nix
  ];

  networking.hostName = "immich";

  mine = {
    immich.enable = true;
  };
}
