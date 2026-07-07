{
  flake.modules.nixos.zfs-host = { lib, ... }: {
    boot.supportedFilesystems = lib.mkDefault [ "zfs" ];
  };
}
