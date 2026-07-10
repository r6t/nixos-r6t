{
  flake.modules.nixos.zfs-host = { lib, ... }: {
    imports = [
      ../../nixos/zfs-pool/options.nix
      ../../nixos/zfs-pool/config.nix
    ];

    boot.supportedFilesystems = lib.mkDefault [ "zfs" ];
  };
}
