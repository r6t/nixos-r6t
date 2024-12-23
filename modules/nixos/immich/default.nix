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
      environment = {
        IMMICH_MACHINE_LEARNING_URL = lib.mkForce "http://100.64.0.27:3003";
      };
      settings = {
        UPLOAD_LOCATION = "/mnt/thunderbay/4TB-B/immich/upload";
        THUMB_LOCATION = "/mnt/thunderbay/4TB-B/immich/thumbs";
        ENCODED_VIDEO_LOCATION = "/mnt/thunderbay/4TB-B/immich/encoded-video";
        PROFILE_LOCATION = "/mnt/thunderbay/4TB-B/immich/profile";
        BACKUP_LOCATION = "/mnt/thunderbay/4TB-B/immich/backups";
        IMMICH_MACHINE_LEARNING_URL = lib.mkForce "http://100.64.0.27:3003";
      };
    };
    systemd.services.immich = {
      after = [ "tailscaled.service" "thunderbay.service" ];
      requires = [ "thunderbay.service" ];
      serviceConfig = {
        ReadOnlyPaths = [ "/mnt/thunderbay/4TB-B/Pictures/" ];
      };
    };
  };
}
