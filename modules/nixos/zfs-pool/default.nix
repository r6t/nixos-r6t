{ lib, config, pkgs, ... }:

let
  cfg = config.mine.zfs-pool;
in
{
  options.mine.zfs-pool = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        poolName = lib.mkOption {
          type = lib.types.str;
          description = "Name of the ZFS pool to import and unlock";
        };
        keyFile = lib.mkOption {
          type = lib.types.str;
          description = "Absolute path to the key file used to unlock the ZFS pool";
        };
        after = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Systemd after";
        };
        requires = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Systemd requires";
        };
      };
      config = { };
    });
    default = { };
    description = "Declare ZFS pools to import, unlock, and mount via systemd";
  };

  config = lib.mkIf (cfg != { }) {
    # Enable ZFS support
    boot.supportedFilesystems = [ "zfs" ];

    # Create a systemd service for each pool
    systemd.services = lib.mapAttrs'
      (name: pool:
        lib.nameValuePair "zfs-pool-${name}" {
          enable = true;
          description = "Import, unlock, and mount ZFS pool ${pool.poolName}";
          wantedBy = [ "multi-user.target" ];
          inherit (pool) after requires;
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            # Import pool, ignore error if already imported
            if ! ${pkgs.zfs}/bin/zpool list ${pool.poolName} >/dev/null 2>&1; then
              ${pkgs.zfs}/bin/zpool import ${pool.poolName} || ${pkgs.zfs}/bin/zpool import -f ${pool.poolName} || true
            fi

            # Load key, ignore failure if already unlocked
            ${pkgs.zfs}/bin/zfs load-key -L file://${pool.keyFile} ${pool.poolName} || true

            # Mount zfs datasets, ignore error if already mounted
            ${pkgs.zfs}/bin/zfs mount -a || true
          '';
        }
      )
      cfg;
  };
}
