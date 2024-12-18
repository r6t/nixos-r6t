{ lib, config, ... }:

{ 
    options = {
      mine.immich.enable =
        lib.mkEnableOption "enable immich server";
    };
    config = lib.mkIf config.mine.immich.enable { 
      services.immich = {
        enable = true;
        host = "0.0.0.0";
        port = 2283;
        mediaLocation = "/mnt/thunderbay/4TB-B/immich";
        settings = {
          UPLOAD_LOCATION = "/mnt/thunderbay/4TB-B/immich/upload";
          THUMB_LOCATION = "/mnt/thunderbay/4TB-B/immich/thumbs";
          ENCODED_VIDEO_LOCATION = "/mnt/thunderbay/4TB-B/immich/encoded-video";
          PROFILE_LOCATION = "/mnt/thunderbay/4TB-B/immich/profile";
          BACKUP_LOCATION = "/mnt/thunderbay/4TB-B/immich/backups";
        };
      };
      systemd.services.immich.after = [ "thunderbay.service" ];
      systemd.services.immich.requires = [ "thunderbay.service" ];

    };
}
