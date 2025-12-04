{ inputs, lib, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  networking = {
    enableIPv6 = false;
    useNetworkd = true;
    hostName = "barrel";
    nameservers = [ "127.0.0.1" ];

    interfaces = {
      # Lower port unused
      eno1.useDHCP = false;
      # Upper port DHCP
      eno2.useDHCP = true;
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

    resolved.enable = lib.mkForce false;

    dnsmasq = {
      enable = true;
      resolveLocalQueries = false;
      settings = {
        # Bind to interfaces as they come up (timing fix)
        bind-dynamic = true;

        # Explicit DNS listening addresses
        listen-address = [ "127.0.0.1" "192.168.6.1" ];

        # DHCP only on LAN interface
        interface = "enp100s0";

        # DNS Configuration only (DHCP handled by systemd-networkd)
        no-resolv = true;
        no-poll = true;
        cache-size = 10000;
        no-negcache = true;
        dns-forward-max = 1500;
        domain-needed = true;
        # Upstream DNS - NextDNS
        server = [ "127.0.0.1#5353" ];
      };
    };

    nextdns = {
      enable = true;
      arguments = [
        "-config-file"
        "/mnt/nextdns.conf"
        "-listen"
        "127.0.0.1:5353"
      ];
    };
  };

  system.stateVersion = "23.11";

  systemd = {
    tmpfiles.rules = [ ];
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
    env.enable = true;
    fwupd.enable = true;
    iperf.enable = true;
    fzf.enable = true;
    localization.enable = true;
    nix.enable = true;
    ssh.enable = true;
    user.enable = true;
  };
}
