{ lib, cfg }:

{
  # Router kernel configuration
  boot = {
    kernel.sysctl = {
      # Router essentials
      "net.ipv4.conf.all.forwarding" = 1;
      # Disable IPv6 forwarding
      "net.ipv6.conf.all.forwarding" = 0;
      # Accept TCP packets that are "out of window" without marking INVALID.
      # Required for NAT environments where the AP may send TCP control frames
      # (RST/FIN) on behalf of idle clients, which corrupts conntrack state and
      # causes legitimate return traffic from cloud servers to be dropped.
      "net.netfilter.nf_conntrack_tcp_be_liberal" = 1;

      # Security hardening
      "net.ipv4.conf.all.rp_filter" = 2; # Loose mode for router/DHCP compatibility
      "net.ipv4.conf.all.accept_source_route" = 0;
      "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
      "net.ipv4.conf.all.log_martians" = 1;
    };
    kernelModules = lib.mkIf cfg.cake.enable [ "sch_cake" "ifb" "act_mirred" ];
  };
}
