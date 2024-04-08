{ lib, config, ... }: 

{ 
    options = {
      mine.jellyfin.enable =
        lib.mkEnableOption "enable jellyfin";
    };

    config = lib.mkIf config.mine.jellyfin.enable { 
      services.jellyfin = {
        enable = true;
        user = "r6t";
        group = "users";
        dataDir = "/home/r6t/external-ssd/2TB-E/app-storage/jellyfin";
        configDir = "/home/r6t/external-ssd/2TB-E/config/jellyfin";
        cacheDir = "/home/r6t/external-ssd/2TB-E/cache/jellyfin";
        logDir = "/home/r6t/external-ssd/2TB-E/log/jellyfin";
	};
    };
}
