{ lib, inputs, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.sops-nix.nixosModules.sops
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  time.timeZone = "America/Los_Angeles";
  networking = {
    hostName = "moon";
    enableIPv6 = true;
  };

  networking = {
    useDHCP = lib.mkDefault true;
    networkmanager.enable = false;
    useNetworkd = false;
    bridges.br1 = {
      interfaces = [ "enp0s13f0u4" ];
    };

    interfaces = {
      enp0s13f0u4.useDHCP = false;
      enp89s0.useDHCP = true;
      br1.useDHCP = true;
    };

    # Allow DHCP on bridge interface
    dhcpcd.denyInterfaces = [ "enp0s*" "wl*" ]; # Permit br1
  };

  system.stateVersion = "23.11";

  mine = {
    alloy.enable = true;
    bolt.enable = true;
    bootloader.enable = true;
    bridge.enable = false;
    caddy.enable = true;
    env.enable = true;
    fwupd.enable = true;
    fzf.enable = true;
    grafana.enable = true;
    immich.enable = true;
    incus.enable = true;
    karakeep.enable = true;
    localization.enable = true;
    loki.enable = true;
    libvirtd.enable = false;
    llm.enable = true;
    moonstore.enable = true;
    networkmanager.enable = false;
    nix.enable = true;
    nvidia-cuda.enable = true;
    prometheus.enable = true;
    prometheus-node-exporter.enable = true;
    sops.enable = true;
    ssh.enable = true;
    syncthing.enable = true;
    tailscale.enable = true;
    uptime-kuma.enable = true;
    user.enable = true;

    home = {
      fish.enable = true;
      git.enable = true;
      home-manager.enable = true;
      nixvim.enable = true;
    };
  };
}

