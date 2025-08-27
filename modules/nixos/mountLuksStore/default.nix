{ lib, config, ... }:

let
  cfg = config.mine.mountLuksStore;
in
{
  options.mine.mountLuksStore = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        device = lib.mkOption {
          type = lib.types.str;
          description = "Block device of the LUKS store (e.g. /dev/disk/by-label/FOO or /dev/disk/by-uuid/UUID)";
        };
        keyFile = lib.mkOption {
          type = lib.types.str;
          description = "Absolute path to the keyfile used to unlock the LUKS store";
        };
        mountPoint = lib.mkOption {
          type = lib.types.str;
          description = "Mount point for the unlocked device";
        };
        fsType = lib.mkOption {
          type = lib.types.str;
          default = "ext4";
        };
        fsOptions = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "defaults" ];
        };
      };
      config = { };
    });
    default = { };
    description = "Declare additional LUKS-encrypted stores to unlock post-boot via systemd";
  };

  config = lib.mkIf (cfg != { }) {
    # 1) Emit /etc/crypttab entries
    environment.etc."crypttab".text = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: store: "${name} ${store.device} ${store.keyFile} luks,nofail") cfg
    );

    # 2) Create each mount point directory
    systemd.tmpfiles.rules = lib.mapAttrsToList (_: store: "d ${store.mountPoint} 0755 root root -") cfg;

    # 3) Declare mounts in fileSystems
    fileSystems = lib.foldl'
      (acc: st: acc // {
        "${st.mountPoint}" = {
          device = "/dev/mapper/${st.name}";
          inherit (st) fsType;
          options = st.fsOptions;
        };
      })
      { }
      (lib.mapAttrsToList
        (name: store: {
          inherit name;
          inherit (store) mountPoint fsType fsOptions;
        })
        cfg);
  };
}
