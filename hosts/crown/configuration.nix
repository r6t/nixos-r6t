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

      #      # Bridge performance optimizations
      #      "net.bridge.bridge-nf-call-iptables" = 1;
      #      "net.bridge.bridge-nf-call-ip6tables" = 1;
      #      "net.bridge.bridge-nf-filter-vlan-tagged" = 0;
      #      
      #      # High-performance networking
      #      "net.core.netdev_max_backlog" = 50000;
      #      "net.core.netdev_budget" = 600;
      #      "net.core.netdev_budget_usecs" = 2000;
      #
      #       # Additional optimizations for high container count
      #      "net.core.somaxconn" = 32768;
      #      "net.ipv4.tcp_max_syn_backlog" = 32768;
      #      "net.core.rmem_max" = 134217728;
      #      "net.core.wmem_max" = 134217728;
    };
    kernelModules = [ "kvm-amd" "kvm" ];
    kernelParams = [ "kvm-amd" "kvm" "reboot=efi" ];
    supportedFilesystems = [ "zfs" ];
    #    extraModprobeConfig = ''
    #      # Mellanox CX312A performance tuning - both ports
    #      options mlx4_en inline_thold=0
    #      options mlx4_core log_num_mgm_entry_size=-7
    #      options mlx4_core enable_sys_tune=1
    #      options mlx4_core num_vfs=0,0  # Disable SR-IOV for simplicity
    #    '';
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
    # useDHCP = false;
    dhcpcd.enable = false;

    bridges = {
      br1 = { interfaces = [ "enp1s0" ]; };
    };

    interfaces = {
      enp1s0.useDHCP = false; # Bridge interface
      enp1s0d1 = {
        useDHCP = true; # Primary host interface
      };
      enp5s0.useDHCP = false; # 2.5G Incus hardware passthrough
      enp6s0.useDHCP = false; # 2.5G Incus hardware passthrough
      enp7s0.useDHCP = false; # 2.5G Incus hardware passthrough
      enp8s0.useDHCP = false; # 2.5G Incus hardware passthrough
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


  systemd.services = {

    caddy = {
      #      after = [ "dnsmasq.service" ];
      #      wants = [ "dnsmasq.service" ];
      after = [ "mnt-crownstore.mount" ];
      wants = [ "mnt-crownstore.mount" ];
    };

    #    dnsmasq = {
    #      after = [ "nextdns.service" ];
    #      wants = [ "nextdns.service" ];
    #    };
    #
    #    nextdns = {
    #      after = [ "mnt-crownstore.mount" ];
    #      wants = [ "mnt-crownstore.mount" ];
    #    };

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
    # Physical interface optimization
    #    mellanox-tuning = {
    #      description = "Optimize Mellanox CX312A + Intel i226 NICs";
    #      after = [ "network.target" ];
    #      wantedBy = [ "multi-user.target" ];
    #
    #      script = ''
    #        echo "=== Optimizing Mellanox CX312A Interfaces ==="
    #        
    #        # Optimize both Mellanox interfaces
    #        for MLX_IFACE in enp1s0 enp1s0d1; do
    #          if ip link show $MLX_IFACE >/dev/null 2>&1; then
    #            echo "Optimizing Mellanox interface: $MLX_IFACE"
    #            
    #            # Hardware offload optimizations  
    #            ${pkgs.ethtool}/bin/ethtool -K $MLX_IFACE gro on
    #            ${pkgs.ethtool}/bin/ethtool -K $MLX_IFACE gso on
    #            ${pkgs.ethtool}/bin/ethtool -K $MLX_IFACE tso on
    #            ${pkgs.ethtool}/bin/ethtool -K $MLX_IFACE lro on
    #            
    #            # Low latency settings
    #            ${pkgs.ethtool}/bin/ethtool -C $MLX_IFACE adaptive-rx off rx-usecs 0 rx-frames 0 || true
    #            
    #            # Large ring buffers for 10G performance
    #            ${pkgs.ethtool}/bin/ethtool -G $MLX_IFACE rx 8192 tx 8192 || true
    #            
    #            # High throughput queue settings
    #            ip link set $MLX_IFACE txqueuelen 10000
    #          fi
    #        done
    #        
    #        echo "=== Optimizing Intel i226 Interfaces ==="
    #        
    #        # Optimize Intel 2.5G interfaces
    #        for INTEL_IFACE in enp5s0 enp6s0 enp7s0 enp8s0; do
    #          if ip link show $INTEL_IFACE >/dev/null 2>&1; then
    #            echo "Optimizing Intel 2.5G interface: $INTEL_IFACE"
    #            
    #            ${pkgs.ethtool}/bin/ethtool -K $INTEL_IFACE gro on gso on tso on || true
    #            ${pkgs.ethtool}/bin/ethtool -G $INTEL_IFACE rx 4096 tx 4096 || true
    #            ip link set $INTEL_IFACE txqueuelen 5000
    #          fi
    #        done
    #
    #        echo "=== Optimizing br1 Bridge ==="
    #        
    #        if ip link show br1 >/dev/null 2>&1; then
    #          ${pkgs.ethtool}/bin/ethtool -K br1 gro on gso on tso on || true
    #          
    #          # Bridge forwarding optimizations
    #          echo 8192 > /sys/class/net/br1/bridge/hash_max
    #          echo 0 > /sys/class/net/br1/bridge/multicast_snooping
    #          echo 300 > /sys/class/net/br1/bridge/forward_delay
    #          
    #          ip link set br1 txqueuelen 10000
    #        fi
    #
    #        echo "=== Optimizing IRQ Affinity ==="
    #        
    #        # Spread interrupts across cores
    #        for irq in $(grep -E "mlx4" /proc/interrupts | cut -d: -f1 | tr -d ' '); do
    #          if [ -n "$irq" ]; then
    #            echo "f" > /proc/irq/$irq/smp_affinity 2>/dev/null || true
    #          fi
    #        done
    #        
    #        for irq in $(grep -E "(enp5s0|enp6s0|enp7s0|enp8s0)" /proc/interrupts | cut -d: -f1 | tr -d ' '); do
    #          if [ -n "$irq" ]; then
    #            echo "f" > /proc/irq/$irq/smp_affinity 2>/dev/null || true
    #          fi
    #        done
    #        
    #        echo "Network optimization complete"
    #      '';
    #
    #      serviceConfig = {
    #        Type = "oneshot";
    #        RemainAfterExit = true;
    #      };
    #    };

    # Runtime hardware-accelerated flowtables
    #    nftables-flowtables = {
    #      description = "Setup hardware-accelerated flowtables for Mellanox CX312A";
    #      after = [ "network.target" "nftables.service" "mellanox-tuning.service" ];
    #      wants = [ "nftables.service" ];
    #      wantedBy = [ "multi-user.target" ];
    #      
    #      serviceConfig = {
    #        Type = "oneshot";
    #        RemainAfterExit = true;
    #      };
    #      
    #      script = ''
    #        # Wait for interfaces to be ready
    #        sleep 10
    #        
    #        echo "Setting up hardware-accelerated flowtables..."
    #        
    #        # Bridge flowtable with hardware offload
    #        if ip link show br1 >/dev/null 2>&1; then
    #          echo "Adding hardware-accelerated flowtable for br1"
    #          
    #          ${pkgs.nftables}/bin/nft add table bridge filter 2>/dev/null || true
    #          ${pkgs.nftables}/bin/nft add flowtable bridge filter br_fastpath { \
    #            hook ingress priority filter + 10 \; \
    #            devices = { br1 } \; \
    #            flags offload \; \
    #          } 2>/dev/null || echo "Bridge flowtable setup failed (may not support offload)"
    #          
    #          ${pkgs.nftables}/bin/nft add chain bridge filter FORWARD { \
    #            type filter hook forward priority filter \; policy accept \; \
    #          } 2>/dev/null || true
    #          
    #          ${pkgs.nftables}/bin/nft add rule bridge filter FORWARD \
    #            ct state established,related meta l4proto {tcp,udp} flow add @br_fastpath 2>/dev/null || true
    #        fi
    #        
    #        # Management interface flowtable  
    #        if ip link show enp1s0d1 >/dev/null 2>&1; then
    #          echo "Adding hardware-accelerated flowtable for management interface"
    #          
    #          ${pkgs.nftables}/bin/nft add table inet filter 2>/dev/null || true
    #          ${pkgs.nftables}/bin/nft add flowtable inet filter mgmt_fastpath { \
    #            hook ingress priority filter + 10 \; \
    #            devices = { enp1s0d1 } \; \
    #            flags offload \; \
    #          } 2>/dev/null || echo "Management flowtable setup failed (may not support offload)"
    #          
    #          ${pkgs.nftables}/bin/nft add chain inet filter FORWARD { \
    #            type filter hook forward priority filter \; policy accept \; \
    #          } 2>/dev/null || true
    #          
    #          ${pkgs.nftables}/bin/nft add rule inet filter FORWARD \
    #            ct state established,related meta l4proto {tcp,udp} flow add @mgmt_fastpath 2>/dev/null || true
    #        fi
    #        
    #        echo "Hardware flowtable setup complete"
    #      '';
    #      
    #      preStop = ''
    #        ${pkgs.nftables}/bin/nft delete table bridge filter 2>/dev/null || true
    #        ${pkgs.nftables}/bin/nft delete table inet filter 2>/dev/null || true
    #      '';
    #    };
  };

  systemd = {
    tmpfiles.rules = [
      "d /mnt/thunderbay 0755 root root -"
      "d /mnt/thunderkey 0755 root root -"
      "L /etc/caddy/Caddyfile - - - - /mnt/crownstore/Sync/app-config/caddy/crown.Caddyfile"
      "L /etc/caddy/caddy.env - - - - /mnt/crownstore/Sync/app-config/caddy/crown.caddy.env"
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
