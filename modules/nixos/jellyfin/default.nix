{ lib, config, pkgs, ... }:

{
  options = {
    mine.jellyfin.enable = lib.mkEnableOption "jellyfin server module";
    mine.jellyfin.logDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/log/jellyfin";
      description = "Directory where Jellyfin will write its logs.";
    };
    mine.jellyfin.dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/jellyfin";
      description = "Directory where Jellyfin will store its media data.";
    };
    mine.jellyfin.cacheDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/cache/jellyfin";
      description = "Directory where Jellyfin will store its cache files.";
    };
    mine.jellyfin.configDir = lib.mkOption {
      type = lib.types.str;
      default = "/etc/jellyfin";
      description = "Directory for Jellyfin configuration files.";
    };
  };

  config = lib.mkIf config.mine.jellyfin.enable {
    services.jellyfin = {
      enable = true;
      user = 1000;
      group = 100;
      logDir = config.mine.jellyfin.logDir;
      dataDir = config.mine.jellyfin.dataDir;
      cacheDir = config.mine.jellyfin.cacheDir;
      configDir = config.mine.jellyfin.configDir;
    };
    environment.systemPackages = [
      pkgs.jellyfin
      pkgs.jellyfin-web
      pkgs.jellyfin-ffmpeg
    ];
  };
}
