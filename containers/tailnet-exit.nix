{ lib, ... }:

{
  imports = [
    ./lib/wg-exit-node.nix
  ];

  mine.exit-node-routing = {
    enable = true;
    enableTailscale = true;
  };

  # Auth key file bind-mounted by incus profile from host storage.
  # Use an ephemeral + reusable key so exit nodes auto-join the tailnet
  # on launch and auto-expire when deleted.
  mine.tailscale.authKeyFile = "/etc/tailscale/auth-key";

  # Exit nodes are administered through `incus exec` on crown; avoid exposing
  # an extra management daemon on LAN/tailnet interfaces.
  services.openssh.enable = lib.mkForce false;
}
