{
  imports = [
    ./lib/base.nix
    ./lib/mullvad-dns.nix
    ../modules/nixos/exit-node-routing/default.nix
    ../modules/nixos/tailscale/default.nix
  ];

  mine.exit-node-routing.enable = true;
}

