{ inputs, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.sops-nix.nixosModules.sops
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  # Caddy container passthru to internal monitoring services
  networking.firewall = {
    allowedTCPPorts = [ 3000 9001 ]; # Grafana + Prometheus
    extraCommands = ''
      iptables -A INPUT -s 172.22.0.0/24 -j ACCEPT
    '';
  };

  time.timeZone = "America/Los_Angeles";
  networking = {
    hostName = "moon";
    enableIPv6 = true;
  };

  system.stateVersion = "23.11";

  mine = {
    alloy.enable = true;
    bolt.enable = true;
    bootloader.enable = true;
    bridge.enable = true;
    docker.enable = true;
    env.enable = true;
    fwupd.enable = true;
    fzf.enable = true;
    grafana.enable = true;
    karakeep.enable = true;
    localization.enable = true;
    loki.enable = true;
    libvirtd.enable = true;
    moonstore.enable = true;
    networkmanager.enable = true;
    nix.enable = true;
    nixpkgs.enable = true;
    nvidia-cuda.enable = true;
    prometheus.enable = true;
    prometheus-node-exporter.enable = true;
    sops.enable = true;
    ssh.enable = true;
    syncthing.enable = true;
    tailscale.enable = true;
    user.enable = true;

    home = {
      fish.enable = true;
      git.enable = true;
      home-manager.enable = true;
      nixvim.enable = true;
    };
  };
}

