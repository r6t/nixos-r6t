{ lib, config, ... }:

{
  options = {
    mine.pinchflat.enable = lib.mkEnableOption "enable pinchflat";
  };

  config = lib.mkIf config.mine.pinchflat.enable {
    # 8945/tcp
    services.pinchflat = {
      enable = true;
      mediaDir = "/home/r6t/Sync/pinchflat/media";
      user = "r6t";
      group = "users";
      selfhosted = true;
      extraConfig = {
        YT_DLP_COOKIES_FROM_BROWSER = "firefox";
      };
    };

    # service gets activated on demand, not automatically on boot
    systemd.services.pinchflat.wantedBy = lib.mkForce [ ];
  };
}
