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
          description = "Systemd units this service should start after";
        };
        requires = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Systemd units this service requires";
        };
        allowRemoteReplication = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Allow passwordless sudo for ZFS receive operations (for remote replication target)";
        };
        snapshots = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable automatic snapshot management for all datasets in this pool";
          };
          daily = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Enable daily snapshots";
            };
            keep = lib.mkOption {
              type = lib.types.int;
              default = 7;
              description = "Number of daily snapshots to keep";
            };
            time = lib.mkOption {
              type = lib.types.str;
              default = "02:00";
              description = "Time to run daily snapshots (HH:MM format)";
            };
          };
          weekly = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Enable weekly snapshots";
            };
            keep = lib.mkOption {
              type = lib.types.int;
              default = 4;
              description = "Number of weekly snapshots to keep";
            };
            time = lib.mkOption {
              type = lib.types.str;
              default = "03:00";
              description = "Time to run weekly snapshots (HH:MM format)";
            };
            dayOfWeek = lib.mkOption {
              type = lib.types.str;
              default = "Sun";
              description = "Day of week to run weekly snapshots";
            };
          };
          monthly = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Enable monthly snapshots";
            };
            keep = lib.mkOption {
              type = lib.types.int;
              default = 36;
              description = "Number of monthly snapshots to keep";
            };
            time = lib.mkOption {
              type = lib.types.str;
              default = "04:00";
              description = "Time to run monthly snapshots (HH:MM format)";
            };
            dayOfMonth = lib.mkOption {
              type = lib.types.int;
              default = 1;
              description = "Day of month to run monthly snapshots";
            };
          };
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
    systemd.services = lib.mkMerge [
      # Pool import/mount services
      (lib.mapAttrs'
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
        cfg)

      # Daily snapshot services
      (lib.mapAttrs'
        (name: pool:
          lib.nameValuePair "zfs-snapshot-${name}-daily" {
            inherit (pool.snapshots.daily) enable;
            description = "Daily snapshot of ${pool.poolName} datasets";
            serviceConfig = {
              Type = "oneshot";
            };
            script = ''
              DATE=$(${pkgs.coreutils}/bin/date +%Y-%m-%d)
              CUTOFF_DATE=$(${pkgs.coreutils}/bin/date -d "${toString pool.snapshots.daily.keep} days ago" +%Y-%m-%d)
              
              # Get all datasets in the pool (excluding pool root)
              DATASETS=$(${pkgs.zfs}/bin/zfs list -H -o name -r ${pool.poolName} | ${pkgs.gnugrep}/bin/grep -v "^${pool.poolName}$" || true)
              
              if [ -z "$DATASETS" ]; then
                echo "No datasets found in pool ${pool.poolName}"
                exit 0
              fi
              
              # Create snapshots for each dataset
              for dataset in $DATASETS; do
                echo "Creating daily snapshot: $dataset@daily-$DATE"
                if ! ${pkgs.zfs}/bin/zfs snapshot "$dataset@daily-$DATE"; then
                  echo "ERROR: Failed to create daily snapshot for $dataset" >&2
                fi
              done
              
              # Cleanup old snapshots
              for dataset in $DATASETS; do
                ${pkgs.zfs}/bin/zfs list -H -t snapshot -o name -s creation "$dataset" 2>/dev/null | \
                  ${pkgs.gnugrep}/bin/grep "@daily-" | \
                  while read snap; do
                    SNAP_DATE=$(echo "$snap" | ${pkgs.gnused}/bin/sed 's/.*@daily-//')
                    if [[ "$SNAP_DATE" < "$CUTOFF_DATE" ]]; then
                      echo "Destroying old daily snapshot: $snap"
                      if ! ${pkgs.zfs}/bin/zfs destroy "$snap"; then
                        echo "ERROR: Failed to destroy snapshot $snap" >&2
                      fi
                    fi
                  done
              done
            '';
          }
        )
        (lib.filterAttrs (_: pool: pool.snapshots.enable && pool.snapshots.daily.enable) cfg))

      # Weekly snapshot services
      (lib.mapAttrs'
        (name: pool:
          lib.nameValuePair "zfs-snapshot-${name}-weekly" {
            inherit (pool.snapshots.weekly) enable;
            description = "Weekly snapshot of ${pool.poolName} datasets";
            serviceConfig = {
              Type = "oneshot";
            };
            script = ''
              WEEK=$(${pkgs.coreutils}/bin/date +%Y-W%V)
              
              # Get all datasets in the pool (excluding pool root)
              DATASETS=$(${pkgs.zfs}/bin/zfs list -H -o name -r ${pool.poolName} | ${pkgs.gnugrep}/bin/grep -v "^${pool.poolName}$" || true)
              
              if [ -z "$DATASETS" ]; then
                echo "No datasets found in pool ${pool.poolName}"
                exit 0
              fi
              
              # Create snapshots for each dataset
              for dataset in $DATASETS; do
                echo "Creating weekly snapshot: $dataset@weekly-$WEEK"
                if ! ${pkgs.zfs}/bin/zfs snapshot "$dataset@weekly-$WEEK"; then
                  echo "ERROR: Failed to create weekly snapshot for $dataset" >&2
                fi
              done
              
              # Cleanup old snapshots (keep last N weeks)
              for dataset in $DATASETS; do
                ${pkgs.zfs}/bin/zfs list -H -t snapshot -o name -s creation "$dataset" 2>/dev/null | \
                  ${pkgs.gnugrep}/bin/grep "@weekly-" | \
                  ${pkgs.coreutils}/bin/head -n -${toString pool.snapshots.weekly.keep} | \
                  while read snap; do
                    echo "Destroying old weekly snapshot: $snap"
                    if ! ${pkgs.zfs}/bin/zfs destroy "$snap"; then
                      echo "ERROR: Failed to destroy snapshot $snap" >&2
                    fi
                  done
              done
            '';
          }
        )
        (lib.filterAttrs (_: pool: pool.snapshots.enable && pool.snapshots.weekly.enable) cfg))

      # Monthly snapshot services
      (lib.mapAttrs'
        (name: pool:
          lib.nameValuePair "zfs-snapshot-${name}-monthly" {
            inherit (pool.snapshots.monthly) enable;
            description = "Monthly snapshot of ${pool.poolName} datasets";
            serviceConfig = {
              Type = "oneshot";
            };
            script = ''
              MONTH=$(${pkgs.coreutils}/bin/date +%Y-%m)
              
              # Get all datasets in the pool (excluding pool root)
              DATASETS=$(${pkgs.zfs}/bin/zfs list -H -o name -r ${pool.poolName} | ${pkgs.gnugrep}/bin/grep -v "^${pool.poolName}$" || true)
              
              if [ -z "$DATASETS" ]; then
                echo "No datasets found in pool ${pool.poolName}"
                exit 0
              fi
              
              # Create snapshots for each dataset
              for dataset in $DATASETS; do
                echo "Creating monthly snapshot: $dataset@monthly-$MONTH"
                if ! ${pkgs.zfs}/bin/zfs snapshot "$dataset@monthly-$MONTH"; then
                  echo "ERROR: Failed to create monthly snapshot for $dataset" >&2
                fi
              done
              
              # Cleanup old snapshots (keep last N months)
              for dataset in $DATASETS; do
                ${pkgs.zfs}/bin/zfs list -H -t snapshot -o name -s creation "$dataset" 2>/dev/null | \
                  ${pkgs.gnugrep}/bin/grep "@monthly-" | \
                  ${pkgs.coreutils}/bin/head -n -${toString pool.snapshots.monthly.keep} | \
                  while read snap; do
                    echo "Destroying old monthly snapshot: $snap"
                    if ! ${pkgs.zfs}/bin/zfs destroy "$snap"; then
                      echo "ERROR: Failed to destroy snapshot $snap" >&2
                    fi
                  done
              done
            '';
          }
        )
        (lib.filterAttrs (_: pool: pool.snapshots.enable && pool.snapshots.monthly.enable) cfg))
    ];

    # Create systemd timers for automatic snapshots
    systemd.timers = lib.mkMerge [
      # Daily snapshot timers
      (lib.mapAttrs'
        (name: pool:
          lib.nameValuePair "zfs-snapshot-${name}-daily" {
            inherit (pool.snapshots.daily) enable;
            description = "Daily snapshot timer for ${pool.poolName}";
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnCalendar = "daily";
              Persistent = true;
              Unit = "zfs-snapshot-${name}-daily.service";
            };
          }
        )
        (lib.filterAttrs (_: pool: pool.snapshots.enable && pool.snapshots.daily.enable) cfg))

      # Weekly snapshot timers
      (lib.mapAttrs'
        (name: pool:
          lib.nameValuePair "zfs-snapshot-${name}-weekly" {
            inherit (pool.snapshots.weekly) enable;
            description = "Weekly snapshot timer for ${pool.poolName}";
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnCalendar = "${pool.snapshots.weekly.dayOfWeek} *-*-* ${pool.snapshots.weekly.time}:00";
              Persistent = true;
              Unit = "zfs-snapshot-${name}-weekly.service";
            };
          }
        )
        (lib.filterAttrs (_: pool: pool.snapshots.enable && pool.snapshots.weekly.enable) cfg))

      # Monthly snapshot timers
      (lib.mapAttrs'
        (name: pool:
          lib.nameValuePair "zfs-snapshot-${name}-monthly" {
            inherit (pool.snapshots.monthly) enable;
            description = "Monthly snapshot timer for ${pool.poolName}";
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnCalendar = "*-*-${toString pool.snapshots.monthly.dayOfMonth} ${pool.snapshots.monthly.time}:00";
              Persistent = true;
              Unit = "zfs-snapshot-${name}-monthly.service";
            };
          }
        )
        (lib.filterAttrs (_: pool: pool.snapshots.enable && pool.snapshots.monthly.enable) cfg))
    ];

    # Configure passwordless sudo for ZFS receive operations (for replication targets)
    security.sudo.extraRules = lib.mkIf (lib.any (pool: pool.allowRemoteReplication) (lib.attrValues cfg)) [
      {
        users = [ "r6t" ];
        commands = [
          {
            command = "${pkgs.zfs}/bin/zfs receive";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.zfs}/bin/zfs receive *";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.zfs}/bin/zfs list";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.zfs}/bin/zfs list *";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.zfs}/bin/zpool list";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.zfs}/bin/zpool list *";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
