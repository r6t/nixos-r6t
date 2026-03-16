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
}
