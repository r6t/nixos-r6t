{ lib, cfg, nftPortSet }:

let
  # Generate extra TCP port rules (LAN-only)
  extraTcpRules = lib.concatMapStringsSep "\n"
    (port: ''
      iifname "${cfg.lanInterface}" tcp dport ${toString port} accept
    '')
    cfg.nftablesAllowFromLan.extraTcpPorts;

  # Generate extra UDP port rules (LAN-only)
  extraUdpRules = lib.concatMapStringsSep "\n"
    (port: ''
      iifname "${cfg.lanInterface}" udp dport ${toString port} accept
    '')
    cfg.nftablesAllowFromLan.extraUdpPorts;

  sourceTcpRules = lib.concatMapStringsSep "\n"
    (rule: ''
      iifname "${cfg.lanInterface}" ip saddr ${rule.source} tcp dport ${nftPortSet rule.ports} accept
    '')
    cfg.nftablesAllowFromLan.sourceTcpPorts;

  mssClampingRule = lib.optionalString cfg.mssClamping ''
    chain forward_mss {
      type filter hook forward priority 0; policy accept;
      oifname "${cfg.wanInterface}" tcp flags syn tcp option maxseg size set rt mtu
    }
  '';

  flowOffloadRule = lib.optionalString cfg.flowOffload ''
    flowtable f {
      hook ingress priority 0;
      devices = { "${cfg.wanInterface}", "${cfg.lanInterface}" };
    }
    chain forward_offload {
      type filter hook forward priority 5; policy accept;
      ip protocol { tcp, udp } flow add @f
    }
  '';
in
{
  networking.nftables = {
    enable = true;
    ruleset = ''
      table inet filter {
        ${mssClampingRule}
        ${flowOffloadRule}
        chain input {
          type filter hook input priority 0; policy drop;
          # Loopback always allowed
          iifname "lo" accept

          # DHCP from LAN (before conntrack)
          iifname "${cfg.lanInterface}" udp dport 67 accept

          # Established/related connections (return traffic for outbound connections)
          ct state { established, related } accept

          # Invalid packets - log (rate-limited) and drop
          ct state invalid limit rate 5/minute burst 5 packets log prefix "INVALID-PKT: "
          ct state invalid drop

          # Explicitly drop NEW connections from WAN (defense in depth)
          iifname "${cfg.wanInterface}" ct state new limit rate 5/minute burst 5 packets log prefix "WAN-INPUT-DROP: "
          iifname "${cfg.wanInterface}" ct state new drop

          # ICMP from LAN only (no WAN ping)
          iifname "${cfg.lanInterface}" ip protocol icmp accept

          # SSH from LAN only
          iifname "${cfg.lanInterface}" tcp dport 22 accept

          # DNS from LAN only
          iifname "${cfg.lanInterface}" tcp dport 53 accept
          iifname "${cfg.lanInterface}" udp dport 53 accept

          # Extra ports from LAN only
          ${extraTcpRules}
          ${extraUdpRules}
          ${sourceTcpRules}
        }
        chain output {
          type filter hook output priority 0; policy accept;
          # Allow all output from router (DHCP responses, DNS responses, updates, etc.)
        }
        chain forward {
          type filter hook forward priority 0; policy drop;
          ct state { established, related } accept
          # Do not drop INVALID in the forward chain. Packets are marked INVALID
          # when their conntrack entry has expired (e.g. cloud server sends a FIN
          # or RST after conntrack tore down a half-closed TCP session for an IoT
          # device). Dropping them here silently kills legitimate return traffic.
          # The policy drop handles anything not explicitly accepted.
          # LAN -> WAN
          iifname "${cfg.lanInterface}" oifname "${cfg.wanInterface}" accept
        }
      }
      table ip nat {
        chain postrouting {
          type nat hook postrouting priority 100; policy accept;
          # Masquerade LAN traffic going to WAN
          oifname "${cfg.wanInterface}" masquerade
        }
      }
    '';
  };
}
