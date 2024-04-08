{ lib, config, pkgs, ... }: { 

    options = {
      mine.download.enable =
        lib.mkEnableOption "set sail";
    };

    config = lib.mkIf config.mine.download.enable { 
      services.download.enable = true;
        virtualisation.oci-containers.backend = "docker";

        # Containers
        virtualisation.oci-containers.containers."download-deemix" = {
          image = "registry.gitlab.com/bockiii/deemix-docker:latest";
          environment = {
            DEEMIX_SINGLE_USER = "true";
            PGID = "100";
            PUID = "1000";
            UMASK_SET = "022";
          };
          volumes = [
            "/home/r6t/external-ssd/2TB-E/config/deemix:/config:rw"
            "/home/r6t/external-ssd/8TB-D/storage/plex/music_unsorted:/downloads:rw"
          ];
          dependsOn = [
            "gluetun"
          ];
          log-driver = "journald";
          extraOptions = [
            "--network=container:gluetun"
          ];
        };
        systemd.services."docker-download-deemix" = {
          serviceConfig = {
            Restart = lib.mkOverride 500 "\"no\"";
          };
          partOf = [
            "docker-compose-download-root.target"
          ];
          unitConfig.UpheldBy = [
            "docker-gluetun.service"
          ];
          wantedBy = [
            "docker-compose-download-root.target"
          ];
        };
        virtualisation.oci-containers.containers."download-lidarr" = {
          image = "linuxserver/lidarr:latest";
          environment = {
            PGID = "100";
            PUID = "1000";
            TZ = "America/Los_Angeles";
          };
          volumes = [
            "/home/r6t/external-ssd/2TB-E/app-storage/download/sabnzbd/complete:/downloads:rw"
            "/home/r6t/external-ssd/2TB-E/config/lidarr:/config:rw"
            "/home/r6t/external-ssd/8TB-D/storage/plex/music:/music:rw"
            "/home/r6t/external-ssd/8TB-D/storage/plex/music_unsorted:/music_unsorted:rw"
          ];
          ports = [
            "8686:8686/tcp"
          ];
          dependsOn = [
            "download-sabnzbd"
          ];
          log-driver = "journald";
          extraOptions = [
            "--network-alias=lidarr"
            "--network=download_default"
          ];
        };
        systemd.services."docker-download-lidarr" = {
          serviceConfig = {
            Restart = lib.mkOverride 500 "\"no\"";
          };
          after = [
            "docker-network-download_default.service"
          ];
          requires = [
            "docker-network-download_default.service"
          ];
          partOf = [
            "docker-compose-download-root.target"
          ];
          unitConfig.UpheldBy = [
            "docker-download-sabnzbd.service"
          ];
          wantedBy = [
            "docker-compose-download-root.target"
          ];
        };
        virtualisation.oci-containers.containers."download-radarr" = {
          image = "lscr.io/linuxserver/radarr:latest";
          environment = {
            PGID = "100";
            PUID = "1000";
            TZ = "America/Los_Angeles";
          };
          volumes = [
            "/home/r6t/external-ssd/2TB-E/app-storage/download/sabnzbd/complete:/downloads:rw"
            "/home/r6t/external-ssd/2TB-E/config/radarr:/config:rw"
            "/home/r6t/external-ssd/8TB-D/storage/plex/movies:/movies:rw"
          ];
          ports = [
            "7878:7878/tcp"
          ];
          dependsOn = [
            "download-sabnzbd"
          ];
          log-driver = "journald";
          extraOptions = [
            "--network-alias=radarr"
            "--network=download_default"
          ];
        };
        systemd.services."docker-download-radarr" = {
          serviceConfig = {
            Restart = lib.mkOverride 500 "\"no\"";
          };
          after = [
            "docker-network-download_default.service"
          ];
          requires = [
            "docker-network-download_default.service"
          ];
          partOf = [
            "docker-compose-download-root.target"
          ];
          unitConfig.UpheldBy = [
            "docker-download-sabnzbd.service"
          ];
          wantedBy = [
            "docker-compose-download-root.target"
          ];
        };
        virtualisation.oci-containers.containers."download-sabnzbd" = {
          image = "linuxserver/sabnzbd:latest";
          environment = {
            PGID = "100";
            PUID = "1000";
            TZ = "America/Los_Angeles";
          };
          volumes = [
            "/home/r6t/external-ssd/2TB-E/app-storage/download/sabnzbd/complete:/downloads:rw"
            "/home/r6t/external-ssd/2TB-E/app-storage/ownload/sabnzbd/downloading:/incomplete-downloads:rw"
            "/home/r6t/external-ssd/2TB-E/config/sabnzbd:/config:rw"
          ];
          dependsOn = [
            "gluetun"
          ];
          log-driver = "journald";
          extraOptions = [
            "--network=container:gluetun"
          ];
        };
        systemd.services."docker-download-sabnzbd" = {
          serviceConfig = {
            Restart = lib.mkOverride 500 "\"no\"";
          };
          partOf = [
            "docker-compose-download-root.target"
          ];
          unitConfig.UpheldBy = [
            "docker-gluetun.service"
          ];
          wantedBy = [
            "docker-compose-download-root.target"
          ];
        };
        virtualisation.oci-containers.containers."sonarr" = {
          image = "linuxserver/sonarr:latest";
          environment = {
            PGID = "100";
            PUID = "1000";
            TZ = "America/Los_Angeles";
          };
          volumes = [
            "/home/r6t/external-ssd/2TB-E/app-storage/download/sabnzbd/complete:/downloads:rw"
            "/home/r6t/external-ssd/2TB-E/config/sonarr:/config:rw"
            "/home/r6t/external-ssd/8TB-D/storage/plex/tv:/tv:rw"
          ];
          ports = [
            "8989:8989/tcp"
          ];
          dependsOn = [
            "download-sabnzbd"
          ];
          log-driver = "journald";
          extraOptions = [
            "--network-alias=sonarr"
            "--network=download_default"
          ];
        };
        systemd.services."docker-sonarr" = {
          serviceConfig = {
            Restart = lib.mkOverride 500 "\"no\"";
          };
          after = [
            "docker-network-download_default.service"
          ];
          requires = [
            "docker-network-download_default.service"
          ];
          partOf = [
            "docker-compose-download-root.target"
          ];
          unitConfig.UpheldBy = [
            "docker-download-sabnzbd.service"
          ];
          wantedBy = [
            "docker-compose-download-root.target"
          ];
        };

        # Networks
        systemd.services."docker-network-download_default" = {
          path = [ pkgs.docker ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStop = "${pkgs.docker}/bin/docker network rm -f download_default";
          };
          script = ''
            docker network inspect download_default || docker network create download_default
          '';
          partOf = [ "docker-compose-download-root.target" ];
          wantedBy = [ "docker-compose-download-root.target" ];
        };

        # Root service
        # When started, this will automatically create all resources and start
        # the containers. When stopped, this will teardown all resources.
        systemd.targets."docker-compose-download-root" = {
          unitConfig = {
            Description = "Root target generated by compose2nix.";
          };
          wantedBy = [ "multi-user.target" ];
        };
  };
}