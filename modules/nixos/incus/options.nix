{ lib, ... }:

{
  options.mine.incus = {
    enable = lib.mkEnableOption "virtualization.incus module";

    profileDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Path to directory containing incus profile YAML files.
        Each .yaml file becomes an incus profile (filename without extension = profile name).
        Profiles are enforced on every nixos-rebuild — local changes are always overwritten.
      '';
    };

    pruneRetiredProfiles = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Delete live incus profiles that no longer have a matching YAML file in profileDir.
        The built-in default profile is never deleted.
      '';
    };
  };
}
