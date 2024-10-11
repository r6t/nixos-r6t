{ lib, config, ... }:

{ 
    options = {
      mine.immich.enable =
        lib.mkEnableOption "enable immich server";
    };
    config = lib.mkIf config.mine.immich.enable { 
      services.immich = {
        enable = true;
				host = "0.0.0.0"; # 3001/tcp default
				user = "r6t";
				group = "users";
				openFirewall = true;
				mediaLocation = /home/r6t/app-storage/immich;
      };
    };
}
