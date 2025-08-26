{ lib, config, pkgs, ... }:

{
  options = {
    mine.jellyfin = {
      enable = lib.mkEnableOption "jellyfin server module";
      logDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/log/jellyfin";
        description = "Directory where Jellyfin will write its logs.";
      };
      dataDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/jellyfin";
        description = "Directory where Jellyfin will store its media data.";
      };
      cacheDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/cache/jellyfin";
        description = "Directory where Jellyfin will store its cache files.";
      };
      configDir = lib.mkOption {
        type = lib.types.str;
        default = "/etc/jellyfin";
        description = "Directory for Jellyfin configuration files.";
      };
    };
  };

  config = lib.mkIf config.mine.jellyfin.enable {
    services.jellyfin = {
      enable = true;
      user = 1000;
      group = 100;
      inherit (config.mine.jellyfin) logDir dataDir cacheDir configDir;
    };
    environment.systemPackages = [
      pkgs.jellyfin
      pkgs.jellyfin-web
      pkgs.jellyfin-ffmpeg
    ];
  };
}
