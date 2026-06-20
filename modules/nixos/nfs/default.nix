{ lib, config, ... }:

let
  cfg = config.mine.nfs;

  exportClients = [ "100.64.0.0/10" ];

  defaultExportOptions = export: [
    "rw"
    "sync"
    "no_subtree_check"
    "root_squash"
    "fsid=${toString export.fsid}"
  ] ++ lib.optional (export.mountPointGuard != null) "mp=${export.mountPointGuard}";

  defaultMountOptions = [
    "_netdev"
    "nfsvers=4.2"
    "proto=tcp"
    "hard"
    "noauto"
    "x-systemd.automount"
    "x-systemd.requires=tailscaled.service"
    "x-systemd.after=tailscaled.service"
    "x-systemd.idle-timeout=600"
    "x-systemd.device-timeout=10s"
    "x-systemd.mount-timeout=30s"
  ];

  hasExports = cfg.exports != { };
  hasMounts = cfg.mounts != { };

  tailnetServiceDeps = [ "tailscaled.service" ];
in
{
  options.mine.nfs = {
    exports = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          path = lib.mkOption {
            type = lib.types.str;
            description = "Local path to export over NFS.";
          };

          fsid = lib.mkOption {
            type = lib.types.int;
            description = "NFS filesystem ID for this export.";
          };

          mountPointGuard = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Mount point that must be mounted before this path is exported.";
          };

          after = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Systemd units that nfs-server should start after.";
          };

          requires = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Systemd units required by nfs-server.";
          };
        };
      });
      default = { };
      description = "Tailnet-only NFS exports.";
    };

    mounts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          device = lib.mkOption {
            type = lib.types.str;
            description = "NFS server and export path, for example crown:/";
          };

          mountPoint = lib.mkOption {
            type = lib.types.str;
            description = "Local mount point for the NFS export.";
          };
        };
      });
      default = { };
      description = "NFS client mounts.";
    };
  };

  config = lib.mkIf (hasExports || hasMounts) {
    boot.supportedFilesystems = [ "nfs" ];

    systemd.tmpfiles.rules =
      (lib.mapAttrsToList (_: export: "d ${export.path} 0755 root root -") cfg.exports)
      ++ (lib.mapAttrsToList (_: mount: "d ${mount.mountPoint} 0755 root root -") cfg.mounts);

    services.nfs.server = lib.mkIf hasExports {
      enable = true;
      exports = lib.concatStringsSep "\n" (lib.mapAttrsToList
        (_: export:
          let
            options = lib.concatStringsSep "," (defaultExportOptions export);
            clientSpecs = lib.concatMapStringsSep " " (client: "${client}(${options})") exportClients;
          in
          "${export.path} ${clientSpecs}"
        )
        cfg.exports);
    };

    systemd.services.nfs-server = lib.mkIf hasExports {
      after = lib.unique (tailnetServiceDeps ++ lib.flatten (lib.mapAttrsToList (_: export: export.after) cfg.exports));
      requires = lib.unique (tailnetServiceDeps ++ lib.flatten (lib.mapAttrsToList (_: export: export.requires) cfg.exports));
    };

    fileSystems = lib.foldl'
      (acc: mount: acc // {
        "${mount.mountPoint}" = {
          inherit (mount) device;
          fsType = "nfs";
          options = defaultMountOptions;
        };
      })
      { }
      (lib.attrValues cfg.mounts);
  };
}
