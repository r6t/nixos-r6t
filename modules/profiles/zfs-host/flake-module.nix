{
  flake.modules.nixos.zfs-host = { lib, ... }: {
    imports = [ ../../nixos/zfs-pool/default.nix ];

    boot.supportedFilesystems = lib.mkDefault [ "zfs" ];
  };
}
