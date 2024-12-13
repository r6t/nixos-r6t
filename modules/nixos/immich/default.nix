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
        port = 3001;
	user = "r6t";
	group = "users";
	openFirewall = true;
        machine-learning.enable = true;
	mediaLocation = "/home/r6t/external-ssd/4TB-B/immich";
      };
      systemd.services.immich.after = [ "thunderbay.service" ];
      systemd.services.immich.requires = [ "thunderbay.service" ];
    };
}
