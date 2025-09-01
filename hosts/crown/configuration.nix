{ inputs, lib, pkgs, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    inputs.nix-flatpak.nixosModules.nix-flatpak
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  boot = {
    # Enable forwarding for containers
    kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };
    kernelModules = [ "kvm-amd" "kvm" ];
    kernelParams = [ "kvm-amd" "kvm" "reboot=efi" ];
    supportedFilesystems = [ "zfs" ];
  };

  fileSystems."/mnt/thunderkey" = {
    device = "/dev/disk/by-label/thunderkey";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  networking = {
    hostId = "5f3e2c0a";
    nftables.enable = true; # Incus requirement
    enableIPv6 = true;
    useNetworkd = true;
    hostName = "crown";
    useDHCP = false;
    dhcpcd.enable = false;

    bridges = {
      br1 = { interfaces = [ "enp1s0" ]; };
    };

    interfaces = {
      enp1s0.useDHCP = false; # Bridge port
      enp5s0.useDHCP = false; # 2.5G Incus hardware passthrough
      enp6s0.useDHCP = false; # 2.5G Incus hardware passthrough
      enp7s0.useDHCP = false; # 2.5G Incus hardware passthrough
      enp9s0.useDHCP = false; # 2.5G Incus hardware passthrough
      enp1s0d1.useDHCP = true; # Primary host interface gets DHCP
      br1.useDHCP = false; # 10G bridge for Incus
    };

    defaultGateway = {
      address = "192.168.6.1";
      interface = "enp1s0d1";
      metric = 100;
    };

    firewall = {
      enable = true;
      checkReversePath = false;
      allowedTCPPorts = [ 22 ];
      trustedInterfaces = [ "br1" "tailscale0" ];
    };
  };

  nix.settings.use-cgroups = true;

  time.timeZone = "America/Los_Angeles";

  services = {
    journald.extraConfig = "SystemMaxUse=500M";
    resolved = {
      enable = true;
      domains = [ "~." ];
    };
  };

  system.stateVersion = "23.11";

  #250830
  # Add container forwarding rules via systemd service
  systemd.services.container-forwarding = {
    description = "Container forwarding rules";
    after = [ "firewall.service" "network-online.target" ];
    wants = [ "firewall.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      # Wait a bit for firewall to be fully ready
      sleep 2
      
      # Check what chains exist first
      echo "Listing current nftables ruleset:"
      ${pkgs.nftables}/bin/nft list ruleset
      
      # Try to add rules to the correct chain (might be nixos-fw-rpfilter or nixos-fw-input)
      # Let's create our own table and chain for forwarding
      ${pkgs.nftables}/bin/nft add table inet container-forward 2>/dev/null || true
      ${pkgs.nftables}/bin/nft add chain inet container-forward forward { type filter hook forward priority filter \; policy accept \; } 2>/dev/null || true
      
      # Add our forwarding rules to our custom chain
      ${pkgs.nftables}/bin/nft add rule inet container-forward forward ip saddr 192.168.6.96/27 accept
      ${pkgs.nftables}/bin/nft add rule inet container-forward forward ip saddr 192.168.6.128/27 accept
      ${pkgs.nftables}/bin/nft add rule inet container-forward forward ip saddr 192.168.6.160/27 accept
      ${pkgs.nftables}/bin/nft add rule inet container-forward forward ip saddr 192.168.6.192/27 accept
      
      # Allow return traffic
      ${pkgs.nftables}/bin/nft add rule inet container-forward forward ip daddr 192.168.6.96/27 ct state related,established accept
      ${pkgs.nftables}/bin/nft add rule inet container-forward forward ip daddr 192.168.6.128/27 ct state related,established accept
      ${pkgs.nftables}/bin/nft add rule inet container-forward forward ip daddr 192.168.6.160/27 ct state related,established accept
      ${pkgs.nftables}/bin/nft add rule inet container-forward forward ip daddr 192.168.6.192/27 ct state related,established accept
      
      # Allow br1 container-to-container
      ${pkgs.nftables}/bin/nft add rule inet container-forward forward iifname "br1" oifname "br1" accept
      
      echo "Container forwarding rules added successfully"
    '';

    preStop = ''
      ${pkgs.nftables}/bin/nft delete table inet container-forward 2>/dev/null || true
    '';
  };

  systemd = {
    tmpfiles.rules = [
      "d /mnt/thunderbay 0755 root root -"
      "d /mnt/thunderkey 0755 root root -"
    ];
    services = {
      systemd-networkd-wait-online.enable = lib.mkForce false;
      nix-daemon.serviceConfig = {
        # Limit CPU usage to 50% for 16 vCPU
        # long builds (nvidia lxcs) impacted general service availability
        CPUQuota = "800%";
      };
    };
    # Reserve NIC device IDs
    network = {
      enable = true;
      links = {
        "10-enp5s0" = { matchConfig.Path = "pci-0000:05:00.0"; linkConfig.Name = "enp5s0"; };
        "10-enp6s0" = { matchConfig.Path = "pci-0000:06:00.0"; linkConfig.Name = "enp6s0"; };
        "10-enp7s0" = { matchConfig.Path = "pci-0000:07:00.0"; linkConfig.Name = "enp7s0"; };
        "10-enp8s0" = { matchConfig.Path = "pci-0000:09:00.0"; linkConfig.Name = "enp8s0"; };
      };
    };
  };

  # modules/
  mine = {
    home = {
      atuin.enable = true;
      fish.enable = true;
      git.enable = true;
      home-manager.enable = true;
      nixvim.enable = true;
      ssh.enable = true;
    };

    alloy.enable = false;
    bolt.enable = true;
    bootloader.enable = true;
    env.enable = true;
    fwupd.enable = true;
    fzf.enable = true;
    iperf.enable = true;
    incus.enable = true;
    localization.enable = true;

    mountLuksStore = {
      crownstore = { device = "/dev/disk/by-uuid/f6425279-658b-49bd-8c3a-1645b5936182"; keyFile = "/root/crownstore.key"; mountPoint = "/mnt/crownstore"; };
      thunderbayA = { device = "/dev/disk/by-uuid/3c429d84-386d-4272-8739-7bd2dcde1159"; keyFile = "/root/3c429d84.key"; mountPoint = "/mnt/thunderbay/8TB-A"; };
      thunderbayC = { device = "/dev/disk/by-uuid/cb067a1e-147b-4052-b561-e2c16c31dd0e"; keyFile = "/root/cb067a1e.key"; mountPoint = "/mnt/thunderbay/8TB-C"; };
      thunderbayD = { device = "/dev/disk/by-uuid/5b66a482-036d-4a76-8cec-6ad15fe2360c"; keyFile = "/root/5b66a482.key"; mountPoint = "/mnt/thunderbay/8TB-D"; };
    };

    nix.enable = true;
    nvidia-cuda.enable = true;
    prometheus-node-exporter.enable = false;
    rdfind.enable = true;
    sops.enable = true;
    ssh.enable = true;
    sshfs.enable = true;
    syncthing.enable = true;
    tailscale.enable = true;
    user.enable = true;
  };
}
