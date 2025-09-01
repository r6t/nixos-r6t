{ pkgs, lib, ... }:
{
  imports = [
    ./r6-lxc-base.nix
    ./r6-lxc-mullvad-dns-add-on.nix
  ];

  networking = {
    hostName = "exit-node-lxc";
    nftables.enable = true;
    firewall = {
      enable = true;
      checkReversePath = "loose";
      trustedInterfaces = [ "tailscale0" ];
    };
  };

  services = {
    tailscale = {
      enable = true;
      useRoutingFeatures = "server";
      extraUpFlags = [
        "--advertise-exit-node"
      ];
    };

    networkd-dispatcher = {
      enable = true;
      rules."50-tailscale" = {
        onState = [ "routable" ];
        # GRO forwarding optimization for exit node performance
        script = ''
          ${lib.getExe pkgs.ethtool} -K eth0 rx-udp-gro-forwarding on rx-gro-list off
        '';
      };
    };
  };


  systemd.
  tmpfiles.rules = [
    # widen the pipe for connection tracking
    "w /proc/sys/net/netfilter/nf_conntrack_max - - - - 1048576"
    "w /proc/sys/net/netfilter/nf_conntrack_buckets - - - - 262144"
  ];
  services = {
    # nftables NAT systemd service
    container-nat = {
      description = "Container NAT and routing rules";
      after = [ "firewall.service" "tailscaled.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 5"; # Wait for Tailscale
      };
      script = ''
        # Clear any existing Tailscale NAT rules that might interfere
        ${pkgs.nftables}/bin/nft flush table ip nat 2>/dev/null || true
          
        # Recreate only our container NAT table
        ${pkgs.nftables}/bin/nft add table ip nat
        ${pkgs.nftables}/bin/nft add chain ip nat postrouting { type nat hook postrouting priority srcnat \; policy accept \; }
          
        # ONLY masquerade Tailscale traffic going out eth0 - no packet marking
        ${pkgs.nftables}/bin/nft add rule ip nat postrouting oifname "eth0" masquerade
          
        # Add forwarding rules
        ${pkgs.nftables}/bin/nft add rule inet nixos-fw nixos-fw-forward iifname "tailscale0" oifname "eth0" accept
        ${pkgs.nftables}/bin/nft add rule inet nixos-fw nixos-fw-forward iifname "eth0" oifname "tailscale0" ct state related,established accept
      '';

      preStop = ''
        ${pkgs.nftables}/bin/nft flush table ip nat 2>/dev/null || true
      '';
    };
    firewall.after = [ "network-online.target" ];
    firewall.wants = [ "network-online.target" ];
  };


  # Exit node performance tuning
  boot.kernel.sysctl = {
    # Network performance optimizations
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    # Increase network buffer sizes
    "net.core.rmem_max" = 134217728;
    "net.core.wmem_max" = 134217728;
    "net.ipv4.tcp_rmem" = "4096 87380 134217728";
    "net.ipv4.tcp_wmem" = "4096 65536 134217728";
    # Optimize for throughput over latency
    "net.ipv4.tcp_slow_start_after_idle" = 0;
  };
}
