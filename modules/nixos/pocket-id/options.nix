{ lib, ... }:

{
  options.mine.pocket-id = {
    enable = lib.mkEnableOption "Pocket ID OIDC provider";

    user = lib.mkOption {
      type = lib.types.str;
      default = "pocket-id";
      description = "User that runs Pocket ID.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "users";
      description = "Group that runs Pocket ID.";
    };

    uid = lib.mkOption {
      type = lib.types.int;
      default = 1000;
      description = "UID for the Pocket ID service user.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/pocket-id";
      description = "Pocket ID data directory.";
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Environment file with Pocket ID secrets such as ENCRYPTION_KEY.
        Defaults to pocket-id.env under dataDir.
      '';
    };

    appUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://localhost:1411";
      description = "Externally reachable Pocket ID URL.";
    };

    trustProxy = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Trust reverse proxy headers.";
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = { };
      description = "Additional services.pocket-id.settings values.";
    };
  };
}
