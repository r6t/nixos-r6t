{
  imports = [
    ./r6-lxc-base.nix
    ../modules/nixos/alloy/default.nix
    ../modules/nixos/grafana/default.nix
    ../modules/nixos/iperf/default.nix
    ../modules/nixos/loki/default.nix
    ../modules/nixos/prometheus/default.nix
    ../modules/nixos/prometheus-node-exporter/default.nix
  ];

  networking.hostName = "monitoring";

  mine = {
    alloy.enable = true;
    grafana.enable = true;
    iperf.enable = true;
    loki.enable = true;
    prometheus.enable = true;
    prometheus-node-exporter.enable = true;
  };
}

