{ lib, config, pkgs, ... }:

{
  options.mine.jellyfin.enable = lib.mkEnableOption "jellyfin server module";

  # Thin wrapper — encodes only flake-specific opinions:
  #   * uid 1000, gid 100 (users) matches the bind-mounted data ownership on crownstore
  #   * openFirewall (LAN access on 8096/8920, 1900/7359)
  #   * pins the ffmpeg + web packages into systemPackages for ad-hoc debugging
  #
  # Everything else (paths, transcoding, hardwareAcceleration, forceEncodingConfig)
  # is set directly via services.jellyfin.* in containers/jellyfin.nix.
  # Upstream defaults for paths are already correct:
  #   dataDir   = /var/lib/jellyfin
  #   configDir = /var/lib/jellyfin/config
  #   cacheDir  = /var/cache/jellyfin
  #   logDir    = /var/lib/jellyfin/log
  config = lib.mkIf config.mine.jellyfin.enable {
    users.users.jellyfin = {
      uid = 1000;
      group = "users";
      isSystemUser = true;
      home = "/var/lib/jellyfin";
    };

    services.jellyfin = {
      enable = true;
      user = "jellyfin";
      group = "users";
      openFirewall = true;
    };

    environment.systemPackages = [
      pkgs.jellyfin
      pkgs.jellyfin-web
      pkgs.jellyfin-ffmpeg
    ];
  };
}
