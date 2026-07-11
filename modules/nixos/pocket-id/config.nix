{ lib, config, ... }:

let
  cfg = config.mine.pocket-id;
in
{
  users.users.${cfg.user} = {
    uid = lib.mkForce cfg.uid;
    inherit (cfg) group;
    isSystemUser = true;
    home = cfg.dataDir;
  };

  services.pocket-id = {
    enable = true;
    inherit (cfg) user group dataDir;
    environmentFile =
      if cfg.environmentFile != null
      then cfg.environmentFile
      else "${cfg.dataDir}/pocket-id.env";
    settings = {
      APP_URL = cfg.appUrl;
      TRUST_PROXY = cfg.trustProxy;
    } // cfg.settings;
  };
}
