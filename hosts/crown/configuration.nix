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
    kernel.sysctl = {
      # Enable forwarding for containers
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
    nftables.enable = true; # Incus requires nftables
    enableIPv6 = true;
    useNetworkd = true;
    hostName = "crown";
    dhcpcd.enable = false;

    bridges = {
      br1 = { interfaces = [ "enp1s0" ]; };
    };

    interfaces = {
      enp1s0.useDHCP = false; # Bridge interface
      enp1s0d1 = {
        useDHCP = true; # Primary host 10G interface picks up DHCP reservation
      };
      enp5s0.useDHCP = false; # 2.5G unused
      enp6s0.useDHCP = false; # 2.5G unused
      enp7s0.useDHCP = false; # 2.5G unused
      enp8s0.useDHCP = false; # 2.5G unused
      br1.useDHCP = true; # 10G bridge for Incus
    };

    firewall = {
      enable = true;
      checkReversePath = false;
      allowedTCPPorts = [ 22 443 ];
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


  systemd.services = {

    caddy = {
      after = [ "mnt-crownstore.mount" ];
      wants = [ "mnt-crownstore.mount" ];
    };

    tailscale-udp-gro = {
      description = "Enable UDP GRO forwarding for Tailscale on Mellanox interfaces";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      script = ''
        ${pkgs.ethtool}/bin/ethtool -K enp1s0d1 rx-udp-gro-forwarding on rx-gro-list off || true
        ${pkgs.ethtool}/bin/ethtool -K br1 rx-udp-gro-forwarding on rx-gro-list off || true
      '';

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };
  };

  systemd = {
    tmpfiles.rules = [
      "d /mnt/thunderbay 0755 root root -"
      "d /mnt/thunderkey 0755 root root -"
      "L /etc/caddy/Caddyfile - - - - /mnt/crownstore/Sync/app-config/caddy/crown.Caddyfile"
      "L /etc/caddy/caddy.env - - - - /mnt/crownstore/Sync/app-config/caddy/crown.caddy.env"
    ];
    services = {
      # Incus storage managment
      incus = {
        # Wait for storage pool before starting incus...
        requires = [ "mnt-crownstore.mount" ];
        after = [ "mnt-crownstore.mount" ];
        serviceConfig = {
          # ... and double check that it's there
          ExecStartPre = "${pkgs.coreutils}/bin/test -d /mnt/crownstore/incus";
        };
      };
      systemd-networkd-wait-online.enable = lib.mkForce false;
      nix-daemon.serviceConfig = {
        # Limit CPU usage to 50% for 16 vCPU
        # long builds (nvidia lxcs) impacted general service availability
        CPUQuota = "800%";
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

    alloy.enable = true;
    bolt.enable = true;
    bootloader.enable = true;
    caddy.enable = true;
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
    prometheus-node-exporter.enable = true;
    rdfind.enable = true;
    sops.enable = true;
    ssh.enable = true;
    sshfs.enable = true;
    syncthing.enable = true;
    tailscale.enable = true;
    user.enable = true;
    zfs-hdd-pool.enable = true;
  };
}
