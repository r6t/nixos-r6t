{ lib, config, pkgs, ... }:

{
  options = { 
    mine.arion-jellyfin = {
      enable =
        lib.mkEnableOption "enable Jellyfin container";
      dataDir = lib.mkOption {
        type = lib.types.path;
        default = "/home/r6t/external-ssd/2TB-E";
        description = "Jellyfin data directory path";
      };
      mediaDirs = lib.mkOption {
        type = lib.types.listOf lib.types.path;
        default = [
          "/home/r6t/external-ssd/8TB-A/movies"
          "/home/r6t/external-ssd/8TB-D/storage/plex/music"
          "/home/r6t/external-ssd/8TB-D/storage/plex/tv"
        ];
        description = "Jellyfin media directory path";
      };
    };
  };


  config = lib.mkIf config.mine.arion-jellyfin.enable {
    virtualisation.arion.enable = true;

    virtualisation.arion.config = {
      config = {
        services.jellyfin = {
          image = "jellyfin/jellyfin";
          ports = [ "8096:8096" ];
          volumes = [
            "${config.mine.arion-jellyfin.dataDir}/config:/config"
            "${config.mine.arion-jellyfin.dataDir}/cache:/cache"
          ] ++ (map (dir: "${dir}:/media/${baseNameOf dir}") config.mine.arion-jellyfin.mediaDirs);
          restart = "unless-stopped";
        };
      };
    };
  };
}
