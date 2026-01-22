{ inputs, lib, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.sops-nix.nixosModules.sops
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  boot = {
    supportedFilesystems = [ "zfs" ];
  };

  fileSystems."/mnt/zfskey" = {
    device = "/dev/disk/by-uuid/213b225c-366b-4577-a56f-366fe577d482";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  networking = {
    hostId = "eb5912c9";
    enableIPv6 = false;
    useNetworkd = true;
    hostName = "barrel";
    nameservers = [ "192.168.6.1" ];
    defaultGateway = {
      address = "192.168.6.1";
      interface = "eno2";
    };

    interfaces = {
      # Lower port unused
      eno1.useDHCP = false;
      # Upper port static IP
      eno2 = {
        useDHCP = false;
        ipv4.addresses = [{
          address = "192.168.6.3";
          prefixLength = 24;
        }];
      };
    };

    firewall = {
      enable = true;
      checkReversePath = false;
      # have a few extras in here while moving services around
      allowedTCPPorts = [ 22 443 2283 8443 ];
      # not sure I need br1 here any longer
      trustedInterfaces = [ "tailscale0" ];
    };
    # firewall = {
    #   enable = false; # Disabled - using nftables instead
    #   checkReversePath = false;
    # };
    # nftables = {
    #   enable = true;
    #   ruleset = ''
    #     table inet filter {
    #       chain input {
    #         type filter hook input priority 0; policy drop;
    #         # Loopback always allowed
    #         iifname "lo" accept
    #         # DHCP from LAN (before conntrack)
    #         iifname "enp100s0" udp dport 67 accept
    #         # Established/related from anywhere
    #         ct state { established, related } accept
    #         ct state invalid drop
    #         # ICMP for diagnostics
    #         ip protocol icmp accept
    #         # SSH from LAN only
    #         iifname "enp100s0" tcp dport 22 accept
    #         # DNS from LAN only
    #         iifname "enp100s0" tcp dport 53 accept
    #         iifname "enp100s0" udp dport 53 accept
    #         # Incus from LAN
    #         iifname "enp100s0" tcp dport 8443 accept
    #       }
    #       chain output {
    #         type filter hook output priority 0; policy accept;
    #         # Allow all output from router (DHCP responses, DNS responses, updates, etc.)
    #       }
    #       chain forward {
    #         type filter hook forward priority 0; policy drop;
    #         ct state { established, related } accept
    #         ct state invalid drop
    #         # LAN -> WAN
    #         iifname "enp100s0" oifname "enp101s0" accept
    #       }
    #     }
    #     table ip nat {
    #       chain postrouting {
    #         type nat hook postrouting priority 100; policy accept;
    #         # Masquerade LAN traffic going to WAN
    #         oifname "enp101s0" masquerade
    #       }
    #     }
    #   '';
    # };
  };
  nix.settings.use-cgroups = true;

  time.timeZone = "America/Los_Angeles";

  services = {
    journald.extraConfig = "SystemMaxUse=500M";
    resolved = {
      enable = true;
      settings.Resolve.Domains = [ "~." ];
    };
  };

  system.stateVersion = "23.11";

  systemd = {
    tmpfiles.rules = [
      "d /mnt/barrel-pool 0755 r6t users -"
      "d /mnt/zfskey 0755 root root -"
    ];
    services = {
      # System configuration
      systemd-networkd-wait-online.enable = lib.mkForce false;
      nix-daemon.serviceConfig = {
        # throttle nix builds to 50% of 16 cores
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

    bootloader.enable = true;
    nixos-r6t-baseline.enable = true;
    fwupd.enable = true;
    iperf.enable = true;
    fzf.enable = true;
    localization.enable = true;
    nix.enable = true;
    sops.enable = true;
    ssh.enable = true;
    tailscale.enable = true;
    user.enable = true;

    zfs-pool = {
      barrel-pool = {
        poolName = "barrel-pool";
        keyFile = "/mnt/zfskey/barrel-pool.key";
        after = [ "mnt-zfskey.mount" ];
        requires = [ "mnt-zfskey.mount" ];

        delegation = {
          enableReceive = true; # Allow r6t to receive snapshots without sudo
        };

        snapshots = {
          enable = false; # Snapshots arrive via replication from crown
        };
      };
    };
  };
}
