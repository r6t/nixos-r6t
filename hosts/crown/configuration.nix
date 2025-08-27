{ inputs, lib, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    inputs.nix-flatpak.nixosModules.nix-flatpak
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  boot = {
    # Enable packet forwarding for containers
    kernel.sysctl = {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };
    kernelModules = [ "kvm-amd" "kvm" ];
    kernelParams = [ "kvm-amd" "kvm" "reboot=efi" ];
    supportedFilesystems = [ "zfs" ];
  };

  time.timeZone = "America/Los_Angeles";
  system.stateVersion = "23.11";

  services = {
    journald.extraConfig = "SystemMaxUse=500M";
    resolved = {
      enable = true;
      domains = [ "~." ];
    };
  };

  # CPU limit nix-daemon on this system
  # long builds (nvidia lxcs) impacted general service availability
  nix.settings.use-cgroups = true;

  # SOPS for secrets management
  sops = {
    defaultSopsFile = "/home/r6t/git/sops-ryan/secrets.yaml";
    age.keyFile = "/home/r6t/.config/sops/age/keys.txt";
    validateSopsFiles = false;
  };

  networking = {
    hostId = "5f3e2c0a";
    nftables.enable = true;
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

    nameservers = [ "192.168.6.1" ];

    firewall = {
      enable = true;
      checkReversePath = false;
      allowedTCPPorts = [ 22 ];
      trustedInterfaces = [ "br1" "tailscale0" ];
      extraInputRules = ''
        tcp dport 22 accept comment "SSH access"
        iifname "tailscale0" accept comment "Tailscale network"
        ip protocol icmp accept comment "Allow ICMP"
      '';

      extraForwardRules = ''
        # CRITICAL: Explicit bridge forwarding rules
        iifname "br1" oifname "enp1s0d1" accept comment "Bridge to physical interface"
        iifname "enp1s0d1" oifname "br1" ct state { established, related } accept comment "Return traffic to bridge"
      
        # Allow inter-bridge traffic
        iifname "br1" oifname "br1" accept comment "Bridge internal forwarding"
      
        # Tailscale forwarding
        iifname "tailscale0" oifname "br1" accept comment "Tailscale to containers"
        iifname "br1" oifname "tailscale0" accept comment "Containers to Tailscale"
      '';
    };
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



  # File systems
  fileSystems."/mnt/thunderkey" = {
    device = "/dev/disk/by-label/thunderkey";
    fsType = "ext4";
    options = [ "noatime" ];
  };


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
