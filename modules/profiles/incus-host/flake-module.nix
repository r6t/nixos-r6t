{
  flake.modules.nixos.incus-host = { config, lib, ... }: {
    imports = [
      ../../nixos/incus/options.nix
      ../../nixos/incus/config.nix
    ];

    mine.incus = {
      profileDir = lib.mkDefault "/home/r6t/git/nixos-r6t/hosts/${config.networking.hostName}/incus-instances";
    };

    networking.nftables.enable = lib.mkDefault true;
  };
}
