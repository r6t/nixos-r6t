{ lib, config, userConfig, ... }:

let
  cfg = config.mine.syncthing;
in
lib.mkMerge [
  {
    services.syncthing = {
      enable = true;
      inherit (cfg) dataDir configDir guiAddress;
      overrideDevices = false;
      overrideFolders = false;
      inherit (cfg) user group;
      settings.gui = lib.optionalAttrs (cfg.guiUser != null) { user = cfg.guiUser; }
        // lib.optionalAttrs (cfg.guiPasswordHash != null) { password = cfg.guiPasswordHash; };
    };
  }
  (lib.mkIf (cfg.sopsSecretNames != [ ]) {
    sops.secrets = lib.genAttrs cfg.sopsSecretNames (_: lib.mkIf config.mine.sops.available {
      owner = config.users.users.${userConfig.username}.name;
    });
  })
]
