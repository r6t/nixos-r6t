{ lib, pkgs, cfg, healthCheckScript }:

lib.mkIf cfg.healthCheck.enable {
  systemd = {
    services.router-health-check = {
      description = "Router health check";
      after = [ "network-online.target" "dnsmasq.service" ];
      wants = [ "network-online.target" ];
      path = [ pkgs.iproute2 pkgs.dig pkgs.nftables pkgs.iputils pkgs.systemd ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${healthCheckScript}/bin/router-health-check";
      };
    };

    timers.router-health-check = {
      description = "Periodic router health check";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = cfg.healthCheck.interval;
      };
    };
  };
}
