{
  flake.modules.nixos.incus-host = { lib, ... }: {
    imports = [
      ../../nixos/incus/options.nix
      ../../nixos/incus/config.nix
    ];

    networking.nftables.enable = lib.mkDefault true;
  };
}
