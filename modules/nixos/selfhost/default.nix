{ lib, config, ... }:

{
  options = {
    mine.selfhost = {
      enable =
        lib.mkEnableOption "enable Jellyfin container";
    };
  };

  config = lib.mkIf config.mine.selfhost.enable {
    virtualisation.oci-containers = {
      backend = "podman";
      containers = {
        jellyfin = {
          image = "jellyfin/jellyfin";
          ports = [ "8096:8096" ];
          volumes = [
            "/home/r6t/external-ssd/2TB-E/config/jellyfin:/config"
            "/home/r6t/external-ssd/2TB-E/cache/jellyfin:/cache"
            "/home/r6t/external-ssd/8TB-A/movies:/media/movies"
            "/home/r6t/external-ssd/8TB-D/storage/plex/music:/media/music"
            "/home/r6t/external-ssd/8TB-D/storage/plex/tv:/media/tv"
          ];
        };
      };
    };
  };
}
