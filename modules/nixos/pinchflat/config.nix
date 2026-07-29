{ lib, ... }:

{
  # 8945/tcp
  services.pinchflat = {
    enable = true;
    mediaDir = "/mnt/thunderbay/8TB-D/storage/plex/youtube";
    user = "r6t";
    group = "users";
    selfhosted = true;
    extraConfig = {
      YT_DLP_COOKIES_FROM_BROWSER = "firefox";
    };
  };

  # service gets activated on demand, not automatically on boot
  systemd.services.pinchflat.wantedBy = lib.mkForce [ ];
}
