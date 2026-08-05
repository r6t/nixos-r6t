{ lib, userConfig, ... }:

{
  options.mine.syncthing = {
    enable = lib.mkEnableOption "enable and configure Syncthing";

    user = lib.mkOption {
      type = lib.types.str;
      default = userConfig.username;
      description = "User that runs Syncthing.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "users";
      description = "Group that runs Syncthing.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "${userConfig.homeDirectory}/Sync";
      description = "Syncthing data directory.";
    };

    configDir = lib.mkOption {
      type = lib.types.str;
      default = "${userConfig.homeDirectory}/.config/syncthing";
      description = "Syncthing config directory.";
    };

    guiAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1:8384";
      description = "Syncthing GUI listen address.";
    };

    guiUser = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional Syncthing GUI username.";
    };

    guiPasswordHash = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional bcrypt password hash for the Syncthing GUI.";
    };

    sopsSecretNames = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Optional SOPS secret names owned by the Syncthing user.";
    };
  };
}
