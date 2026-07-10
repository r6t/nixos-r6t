{ lib, ... }:

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
          default = [ "defaults" "nofail" ];
        };
      };
      config = { };
    });
    default = { };
    description = "Declare additional LUKS-encrypted stores to unlock post-boot via systemd";
  };
}
