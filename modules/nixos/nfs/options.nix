{ lib, ... }:

{
  options.mine.nfs = {
    exports = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: {
        options = {
          path = lib.mkOption {
            type = lib.types.str;
            default = "/srv/nfs/${name}";
            description = "Local path to export over NFS.";
          };

          sourcePath = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Optional backing path used to build a curated export root with bind mounts.";
          };

          includePaths = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Child paths from sourcePath to bind into the exported path.";
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
      }));
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
}
