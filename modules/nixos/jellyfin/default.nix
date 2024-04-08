{ lib, config, ... }: 

let
  cfg = config.services.jellyfin;
in
{ 
    options = {
      mine.jellyfin.enable =
        lib.mkEnableOption "enable jellyfin";
    };

    config = lib.mkIf config.mine.jellyfin.enable { 
      cfg.enable = true;
      cfg.user = "r6t";
      cfg.group = "users";
      cfg.dataDir = "/home/r6t/external-ssd/2TB-E/app-storage/jellyfin";
      cfg.configDir = "/home/r6t/external-ssd/2TB-E/config/jellyfin";
      cfg.cacheDir = "/home/r6t/external-ssd/2TB-E/cache/jellyfin";
      cfg.logDir = "/home/r6t/external-ssd/2TB-E/log/jellyfin";
    };
}