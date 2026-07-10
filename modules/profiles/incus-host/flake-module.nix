{
  flake.modules.nixos.incus-host = { config, lib, ... }: {
    imports = [ ../../nixos/incus/default.nix ];

    mine.incus = {
      enable = lib.mkDefault true;
      profileDir = lib.mkDefault "/home/r6t/git/nixos-r6t/hosts/${config.networking.hostName}/incus-instances";
    };

    networking.nftables.enable = lib.mkDefault true;
  };
}
