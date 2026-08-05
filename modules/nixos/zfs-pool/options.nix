{ lib, ... }:

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
        delegation = {
          enableSend = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Delegate ZFS send permissions to user r6t (for replication source)";
          };
          enableReceive = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Delegate ZFS receive permissions to user r6t (for replication target)";
          };
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
}
