{ lib, config, pkgs, ... }: {

  options = {
    mine.zfs-hdd-pool.enable =
      lib.mkEnableOption "unlock + mount zfs hdd-pool";
  };

  config = lib.mkIf config.mine.zfs-hdd-pool.enable {
    systemd.services.zfs-hdd-pool = {
      enable = true;
      description = "Import, unlock, and mount ZFS hdd-pool";
      wantedBy = [ "multi-user.target" ];
      after = [ "mnt-thunderkey.mount" ];
      requires = [ "mnt-thunderkey.mount" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
                # Import pool, ignore error if already imported
        	if ! ${pkgs.zfs}/bin/zpool list hdd-pool >/dev/null 2>&1; then
                  ${pkgs.zfs}/bin/zpool import hdd-pool || ${pkgs.zfs}/bin/zpool import -f hdd-pool || true
                fi

                # Load key, ignore failure if already unlocked
                ${pkgs.zfs}/bin/zfs load-key -L file:///mnt/thunderkey/hdd-pool.key hdd-pool || true

                # Mount zfs datasets, ignore error if already mounted
                ${pkgs.zfs}/bin/zfs mount -a || true
      '';
    };
  };
}
