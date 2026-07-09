{
  flake.modules.nixos.tailnet-host = { ... }: {
    imports = [
      ../../nixos/tailscale/options.nix
      ../../nixos/tailscale/config.nix
    ];
  };
}
