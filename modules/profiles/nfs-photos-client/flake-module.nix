{
  flake.modules.nixos.nfs-photos-client = { lib, ... }: {
    imports = [ ../../nixos/nfs/default.nix ];

    mine.nfs.mounts.photos = {
      device = lib.mkDefault "crown:/";
      mountPoint = lib.mkDefault "/mnt/thunderbay/8TB-C/Pictures";
    };
  };
}
