{
  flake.modules.nixos.tailnet-host = { ... }: {
    imports = [
      ../../nixos/tailscale/config.nix
    ];
  };
}
