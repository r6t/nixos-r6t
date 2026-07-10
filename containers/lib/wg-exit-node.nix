{ lib, ... }:
{
  imports = [
    ./base.nix
    ./mullvad-dns.nix
    ../../modules/nixos/exit-node-routing/options.nix
    ../../modules/nixos/exit-node-routing/config.nix
    ../../modules/nixos/tailscale/default.nix
  ];

  # Exit nodes must NOT override *.r6t.io to crown's LAN IP.
  # Tailnet clients using these as exit nodes would get an unreachable
  # LAN address instead of resolving via public DNS / tailscale.
  services.dnsmasq.settings.address = lib.mkForce [ ];
}
