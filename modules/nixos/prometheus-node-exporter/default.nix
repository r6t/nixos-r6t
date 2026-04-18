{ lib, config, ... }: {

  options = {
    mine.prometheus-node-exporter.enable =
      lib.mkEnableOption "enable prometheus-node-exporter";
  };

  config = lib.mkIf config.mine.prometheus-node-exporter.enable {
    services.prometheus.exporters.node = {
      enable = true;
      port = 9000;
      enabledCollectors = [ "systemd" "processes" "netstat" "qdisc" "zfs" "hwmon" ];
      extraFlags = [ "--collector.ethtool" "--collector.tcpstat" ];
    };
  };
}
