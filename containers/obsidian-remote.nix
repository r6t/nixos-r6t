{
  imports = [
    ./r6-lxc-base.nix
    ./r6-lxc-mullvad-dns-add-on.nix
    ../modules/nixos/docker/default.nix
  ];

  networking.hostName = "work-obsidian";

  services.dnsmasq.settings.address = [
    "/grafana.r6t.io/192.168.6.1"
    "/r6t.io/192.168.6.10"
  ];

  mine.docker.enable = true;

  virtualisation.oci-containers = {
    backend = "docker";
    containers.obsidian-remote = {
      image = "ghcr.io/sytone/obsidian-remote:latest";
      ports = [ "8088:8088" ];
      volumes = [
        "/vaults:/vaults"
        "/config:/config"
      ];
      environment = {
        PUID = "1000";
        PGID = "100";
        TZ = "America/Los_Angeles";
        DOCKER_MODS = "linuxserver/mods:universal-git";
        CUSTOM_PORT = "8088";
        # Disable basic auth - Pocket-ID handles auth
        CUSTOM_USER = "";
        PASSWORD = "";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 8088 ];
}
