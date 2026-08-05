{
  services.prometheus.exporters.node = {
    enable = true;
    port = 9000;
    enabledCollectors = [ "systemd" "processes" "netstat" "qdisc" "zfs" "hwmon" ];
    extraFlags = [ "--collector.ethtool" "--collector.tcpstat" ];
  };
}
