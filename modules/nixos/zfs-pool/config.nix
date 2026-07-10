{ lib, config, pkgs, ... }:

let
  cfg = config.mine.zfs-pool;
in
lib.mkIf (cfg != { }) {
  # Enable ZFS support
  boot.supportedFilesystems = [ "zfs" ];

  # Don't force-import the root pool during early boot. This flake only
  # uses ZFS for data pools mounted by the systemd services below — root
  # filesystems are LUKS-encrypted ext4. There is no ZFS root pool to
  # force-import, so this option has no practical effect, but setting it
  # explicitly silences the upstream warning that nudges all ZFS users
  # toward the safer 26.11 default (no `-f` on zpool import during
  # initrd). If a future host adds a ZFS root and ever fails to boot
  # because the pool wasn't cleanly exported, add `zfs_force=1` to the
  # kernel cmdline once to recover — that's the upstream recommendation.
  boot.zfs.forceImportRoot = false;

  # Systemd configuration for pool management, snapshots, and delegation
  systemd = {
    services = lib.mkMerge [
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

      # Delegate send permissions (for replication source)
      (lib.mapAttrs'
        (name: pool:
          lib.nameValuePair "zfs-delegate-send-${name}" {
            enable = pool.delegation.enableSend;
            description = "Delegate ZFS send permissions for ${pool.poolName}";
            wantedBy = [ "multi-user.target" ];
            after = [ "zfs-pool-${name}.service" ];
            requires = [ "zfs-pool-${name}.service" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            script = ''
              # Delegate send and snapshot permissions to user r6t
              ${pkgs.zfs}/bin/zfs allow r6t send,snapshot ${pool.poolName}

              # Also delegate to all child datasets recursively
              for dataset in $(${pkgs.zfs}/bin/zfs list -H -o name -r ${pool.poolName} | ${pkgs.gnugrep}/bin/grep -v "^${pool.poolName}$" || true); do
                ${pkgs.zfs}/bin/zfs allow r6t send,snapshot "$dataset"
              done

              echo "ZFS send permissions delegated to r6t on ${pool.poolName}"
            '';
          }
        )
        (lib.filterAttrs (_: pool: pool.delegation.enableSend) cfg))

      # Delegate receive permissions (for replication target)
      (lib.mapAttrs'
        (name: pool:
          lib.nameValuePair "zfs-delegate-receive-${name}" {
            enable = pool.delegation.enableReceive;
            description = "Delegate ZFS receive permissions for ${pool.poolName}";
            wantedBy = [ "multi-user.target" ];
            after = [ "zfs-pool-${name}.service" ];
            requires = [ "zfs-pool-${name}.service" ];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
            };
            script = ''
              # Delegate receive, create, mount, and other necessary permissions to user r6t
              ${pkgs.zfs}/bin/zfs allow r6t create,mount,receive,compression,mountpoint,canmount,quota,reservation ${pool.poolName}

              echo "ZFS receive permissions delegated to r6t on ${pool.poolName}"
            '';
          }
        )
        (lib.filterAttrs (_: pool: pool.delegation.enableReceive) cfg))
    ];

    timers = lib.mkMerge [
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
  };
}
