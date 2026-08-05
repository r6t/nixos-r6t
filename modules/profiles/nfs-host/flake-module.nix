{
  flake.modules.nixos.nfs-host = {
    imports = [
      ../../nixos/nfs/options.nix
      ../../nixos/nfs/config.nix
    ];
  };
}
