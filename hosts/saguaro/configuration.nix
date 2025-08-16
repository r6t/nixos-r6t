{ inputs, lib, userConfig, pkgs, config, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    inputs.nix-flatpak.nixosModules.nix-flatpak
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  boot.kernelParams = [ "kvm-amd" "kvm" "reboot=efi" ];
  boot.kernelModules = [ "kvm-amd" "kvm" ];

  time.timeZone = "America/Los_Angeles";
  system.stateVersion = "23.11";

  services.journald.extraConfig = "SystemMaxUse=500M";

  # Host DNS configuration
  services.resolved = {
    enable = true;
    fallbackDns = [ "1.1.1.1" "8.8.8.8" ];
    domains = [ "~." ];
  };

  # SOPS for secrets management
  sops = {
    defaultSopsFile = "/home/r6t/git/sops-ryan/secrets.yaml";
    age.keyFile = "/home/r6t/.config/sops/age/keys.txt";
    validateSopsFiles = false;
  };

  # WireGuard key preparation service for all VPN locations
  systemd.services.wireguard-keys-setup = {
    description = "Setup WireGuard private keys for all locations";
    wantedBy = [ "multi-user.target" ];
    before = [
      "wireguard-seattle.service"
      "wireguard-vancouver.service"
      "wireguard-oslo.service"
      "wireguard-zurich.service"
    ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      mkdir -p /run/wireguard-keys

      # Process all VPN location keys with proper cleaning
      for location in seattle vancouver oslo zurich; do
        key_file="/run/wireguard-keys/$location.key"
        case $location in
          seattle)   sops_key="/run/secrets/mullvad_wg/a/private_key" ;;
          vancouver) sops_key="/run/secrets/mullvad_wg/b/private_key" ;;
          oslo)      sops_key="/run/secrets/mullvad_wg/c/private_key" ;;
          zurich)    sops_key="/run/secrets/mullvad_wg/d/private_key" ;;
        esac

        # Clean key and verify length
        tr -d '\n' < "$sops_key" > "$key_file"
        chmod 600 "$key_file"

        key_length=$(wc -c < "$key_file")
        if [ "$key_length" -ne 44 ]; then
          echo "ERROR: $location key has wrong length: $key_length"
          exit 1
        fi

        echo "$location WireGuard key setup completed"
      done
    '';
  };

  # Seattle VPN Service - IPv4 Endpoint (Reverted from IPv6)
  systemd.services.wireguard-seattle = {
    description = "WireGuard VPN - Seattle (IPv4)";
    after = [ "network.target" "systemd-networkd.service" "wireguard-keys-setup.service" ];
    wants = [ "network.target" "systemd-networkd.service" ];
    requires = [ "wireguard-keys-setup.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    path = with pkgs; [ wireguard-tools iproute2 ];

    script = ''
            echo "Creating WireGuard Seattle interface (IPv4)..."

            # Remove interface if exists
            ip link delete dev vpn-sea 2>/dev/null || true

            # Create WireGuard interface
            ip link add dev vpn-sea type wireguard
            ip addr add 10.75.52.170/32 dev vpn-sea

            # Configure WireGuard with IPv4 endpoint
            wg setconf vpn-sea /dev/stdin <<EOF
      [Interface]
      PrivateKey = $(cat /run/wireguard-keys/seattle.key)
      ListenPort = 51820

      [Peer]
      PublicKey = kT695K8pTGd+I6Q4a4URU2AdXN2VAtHyi7kNSRjUEiw=
      Endpoint = 23.234.82.127:51820
      AllowedIPs = 0.0.0.0/0
      PersistentKeepalive = 25
      EOF

            # Bring interface up
            ip link set dev vpn-sea up

            echo "WireGuard Seattle (IPv4) interface created successfully"

            # Show status and wait for handshake
            echo "Initial WireGuard status:"
            wg show vpn-sea

            echo "Waiting 30 seconds for handshake..."
            sleep 30

            wg show vpn-sea
            if wg show vpn-sea | grep -q "latest handshake:"; then
              echo "SUCCESS: Seattle IPv4 WireGuard handshake established!"
            else
              echo "WARNING: No handshake detected - check connectivity"
            fi
    '';

    preStop = ''
      ip link delete dev vpn-sea 2>/dev/null || true
    '';
  };

  # Vancouver VPN Service - IPv4 Endpoint
  systemd.services.wireguard-vancouver = {
    description = "WireGuard VPN - Vancouver (IPv4)";
    after = [ "network.target" "systemd-networkd.service" "wireguard-keys-setup.service" ];
    wants = [ "network.target" "systemd-networkd.service" ];
    requires = [ "wireguard-keys-setup.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    path = with pkgs; [ wireguard-tools iproute2 ];

    script = ''
            echo "Creating WireGuard Vancouver interface (IPv4)..."

            ip link delete dev vpn-van 2>/dev/null || true
            ip link add dev vpn-van type wireguard
            ip addr add 10.75.52.171/32 dev vpn-van

            wg setconf vpn-van /dev/stdin <<EOF
      [Interface]
      PrivateKey = $(cat /run/wireguard-keys/vancouver.key)
      ListenPort = 51821

      [Peer]
      PublicKey = EOOkxbmbdHmjb8F45s33yKrIzKWH6lGIgJf2kTOxwFw=
      Endpoint = 149.22.81.207:51820
      AllowedIPs = 0.0.0.0/0
      PersistentKeepalive = 25
      EOF

            ip link set dev vpn-van up
            echo "WireGuard Vancouver (IPv4) interface created"
    '';

    preStop = ''
      ip link delete dev vpn-van 2>/dev/null || true
    '';
  };

  # Oslo VPN Service - IPv4 Endpoint
  systemd.services.wireguard-oslo = {
    description = "WireGuard VPN - Oslo (IPv4)";
    after = [ "network.target" "systemd-networkd.service" "wireguard-keys-setup.service" ];
    wants = [ "network.target" "systemd-networkd.service" ];
    requires = [ "wireguard-keys-setup.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    path = with pkgs; [ wireguard-tools iproute2 ];

    script = ''
            echo "Creating WireGuard Oslo interface (IPv4)..."

            ip link delete dev vpn-osl 2>/dev/null || true
            ip link add dev vpn-osl type wireguard
            ip addr add 10.75.52.172/32 dev vpn-osl

            wg setconf vpn-osl /dev/stdin <<EOF
      [Interface]
      PrivateKey = $(cat /run/wireguard-keys/oslo.key)
      ListenPort = 51822

      [Peer]
      PublicKey = LBlNBTuT7gNEZoAuxO0PTVPpaDuYA7nAeCyMpg9Agyo=
      Endpoint = 178.255.149.165:51820
      AllowedIPs = 0.0.0.0/0
      PersistentKeepalive = 25
      EOF

            ip link set dev vpn-osl up
            echo "WireGuard Oslo (IPv4) interface created"
    '';

    preStop = ''
      ip link delete dev vpn-osl 2>/dev/null || true
    '';
  };

  # Zurich VPN Service - IPv4 Endpoint
  systemd.services.wireguard-zurich = {
    description = "WireGuard VPN - Zurich (IPv4)";
    after = [ "network.target" "systemd-networkd.service" "wireguard-keys-setup.service" ];
    wants = [ "network.target" "systemd-networkd.service" ];
    requires = [ "wireguard-keys-setup.service" ];
    wantedBy = [ "multi-user.target" ]; # Enable when you get the Zurich public key

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    path = with pkgs; [ wireguard-tools iproute2 ];

    script = ''
            echo "Creating WireGuard Zurich interface (IPv4)..."

            ip link delete dev vpn-zur 2>/dev/null || true
            ip link add dev vpn-zur type wireguard
            ip addr add 10.75.52.173/32 dev vpn-zur

            wg setconf vpn-zur /dev/stdin <<EOF
      [Interface]
      PrivateKey = $(cat /run/wireguard-keys/zurich.key)
      ListenPort = 51823

      [Peer]
      PublicKey = 7xVJLzW0nfmACr1VMc+/SiSMFh0j0EI3DrU/8Fnj1zM=
      Endpoint = 146.70.134.34:51820
      AllowedIPs = 0.0.0.0/0
      PersistentKeepalive = 25
      EOF

            ip link set dev vpn-zur up
            echo "WireGuard Zurich (IPv4) interface created"
    '';

    preStop = ''
      ip link delete dev vpn-zur 2>/dev/null || true
    '';
  };

  # Enhanced policy routing service for all VPNs
  systemd.services.vpn-policy-routing = {
    description = "Policy routing for all VPN containers";
    after = [ "wireguard-seattle.service" "wireguard-vancouver.service" "wireguard-oslo.service" ];
    wants = [ "wireguard-seattle.service" "wireguard-vancouver.service" "wireguard-oslo.service" ];
    requires = [ "wireguard-seattle.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    path = with pkgs; [ iproute2 nftables ];

    script = ''
      echo "Setting up policy routing for all VPN locations..."
      
      sleep 5  # Allow interfaces to stabilize
      
      # Ensure nat table exists
      nft add table ip nat 2>/dev/null || true
      nft add chain ip nat POSTROUTING { type nat hook postrouting priority 100 \; } 2>/dev/null || true
      
      # Clean up existing rules
      echo "Cleaning up existing policy rules..."
      ip rule del from 192.168.6.96/27 table 105 2>/dev/null || true   # Seattle
      ip rule del from 192.168.6.128/27 table 106 2>/dev/null || true  # Vancouver  
      ip rule del from 192.168.6.160/27 table 107 2>/dev/null || true  # Oslo
      ip rule del from 192.168.6.192/27 table 108 2>/dev/null || true  # Zurich
      
      # Flush routing tables
      echo "Flushing routing tables..."
      for table in 105 106 107 108; do
        ip route flush table $table 2>/dev/null || true
      done
      
      # Clean up existing NAT rules
      echo "Cleaning up existing NAT rules..."
      nft flush chain ip nat POSTROUTING 2>/dev/null || true
      
      # Setup active VPN routing
      for vpn in "vpn-sea:105:192.168.6.96/27:Seattle" "vpn-van:106:192.168.6.128/27:Vancouver" "vpn-osl:107:192.168.6.160/27:Oslo"; do
        iface=$(echo $vpn | cut -d: -f1)
        table=$(echo $vpn | cut -d: -f2) 
        subnet=$(echo $vpn | cut -d: -f3)
        location=$(echo $vpn | cut -d: -f4)
        
        if ip link show $iface >/dev/null 2>&1; then
          echo "Configuring $location VPN routing..."
          ip route add default dev $iface table $table || continue
          ip rule add from $subnet table $table priority $table || continue
          nft add rule ip nat POSTROUTING ip saddr $subnet oifname "$iface" masquerade || continue
          echo "$location VPN policy routing configured"
        fi
      done
      
      # Show configuration status
      echo "=== Active VPN Policy Rules ==="
      ip rule show | grep -E "10[5-8]" || echo "No VPN policy rules found"
      
      echo "=== VPN Routing Tables ==="
      for table in 105 106 107 108; do
        routes=$(ip route show table $table 2>/dev/null)
        if [ -n "$routes" ]; then
          echo "Table $table: $routes"
        fi
      done
      
      echo "VPN policy routing setup completed successfully"
    '';

    preStop = ''
      echo "Cleaning up VPN policy routing..."
      for subnet in "192.168.6.96/27" "192.168.6.128/27" "192.168.6.160/27" "192.168.6.192/27"; do
        for table in 105 106 107 108; do
          ${pkgs.iproute2}/bin/ip rule del from $subnet table $table 2>/dev/null || true
        done
      done
      
      for table in 105 106 107 108; do
        ${pkgs.iproute2}/bin/ip route flush table $table 2>/dev/null || true
      done
      
      ${pkgs.nftables}/bin/nft flush chain ip nat POSTROUTING 2>/dev/null || true
    '';
  };

  # Networking configuration - Simplified IPv4-focused architecture
  networking = {
    nftables.enable = true;
    enableIPv6 = true; # Keep for LAN use
    useNetworkd = true;
    hostName = "crown";

    useDHCP = false;
    dhcpcd.enable = false;

    # Bridge for all container and VPN traffic
    bridges = {
      br1 = { interfaces = [ "enp1s0" ]; }; # 10G SFP interface
    };

    interfaces = {
      # Physical interfaces
      enp1s0.useDHCP = false; # Bridge member - 10G SFP

      # Main host management interface
      enp1s0d1 = {
        useDHCP = false;
        ipv4.addresses = [{
          address = "192.168.6.2";
          prefixLength = 24;
        }];
      };

      # Bridge interface with VPN container gateway
      br1 = {
        useDHCP = false;
        ipv4.addresses = [{
          address = "192.168.6.3"; # Gateway for VPN containers
          prefixLength = 24;
        }];
      };

      # Dedicated VPN NICs - UNUSED (available for other uses)
      enp5s0.useDHCP = false;
      enp6s0.useDHCP = false;
      enp7s0.useDHCP = false;
      enp9s0.useDHCP = false;
    };

    # Routing tables for all VPN locations
    iproute2 = {
      enable = true;
      rttablesExtraConfig = ''
        105 vpn-sea
        106 vpn-van
        107 vpn-osl
        108 vpn-zur
      '';
    };

    defaultGateway = {
      address = "192.168.6.1";
      interface = "enp1s0d1";
      metric = 100;
    };

    nameservers = [ "192.168.6.1" "1.1.1.1" "8.8.8.8" ];

    # Firewall - All VPN connections through shared bridge
    firewall = {
      enable = true;
      allowedUDPPorts = [ 51820 51821 51822 51823 ]; # All VPN ports
      checkReversePath = false;
      trustedInterfaces = [ "br1" "vpn-sea" "vpn-van" "vpn-osl" "vpn-zur" "tailscale0" ];

      extraInputRules = ''
        # Allow all WireGuard traffic through bridge interface
        iifname "br1" udp dport { 51820, 51821, 51822, 51823 } accept comment "WireGuard VPNs"
        
        # Allow VPN interface traffic
        iifname { "vpn-sea", "vpn-van", "vpn-osl", "vpn-zur" } accept comment "VPN interfaces"
        
        # Allow Tailscale traffic
        iifname "tailscale0" accept comment "Tailscale mesh network"
      '';

      extraForwardRules = ''
        # Container to VPN forwarding
        iifname "br1" oifname { "vpn-sea", "vpn-van", "vpn-osl", "vpn-zur" } accept comment "Container to VPN"
        iifname { "vpn-sea", "vpn-van", "vpn-osl", "vpn-zur" } oifname "br1" ct state related,established accept comment "VPN to container return"

        # Regular container internet access
        iifname "br1" oifname "enp1s0d1" accept comment "Container to internet"
        iifname "enp1s0d1" oifname "br1" ct state related,established accept comment "Internet to container return"
        
        # Tailscale forwarding
        iifname "tailscale0" oifname "br1" accept comment "Tailscale to containers"
        iifname "br1" oifname "tailscale0" accept comment "Containers to Tailscale"
      '';
    };
  };

  # Enable packet forwarding
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv6.conf.default.forwarding" = 1;
  };

  # Disable problematic wait-online service
  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;

  # File systems
  fileSystems."/mnt/thunderkey" = {
    device = "/dev/disk/by-label/thunderkey";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  systemd.tmpfiles.rules = [
    "d /mnt/thunderbay 0755 root root -"
    "d /mnt/thunderkey 0755 root root -"
  ];

  # Your module configuration
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
    caddy.enable = false;
    docker.enable = false;
    env.enable = true;
    fwupd.enable = true;
    fzf.enable = true;
    iperf.enable = true;
    incus.enable = true;
    libvirtd.enable = false;
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

