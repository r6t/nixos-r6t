{ lib, pkgs, cfg, wanWatchdogScript }:

lib.mkIf cfg.wanWatchdog.enable {
  systemd = {
    services.wan-watchdog = {
      description = "WAN connectivity watchdog";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      path = [ pkgs.iputils pkgs.systemd pkgs.coreutils ];

      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${wanWatchdogScript}/bin/wan-watchdog";
        RuntimeDirectory = "wan-watchdog";
      };
    };

    timers.wan-watchdog = {
      description = "Periodic WAN connectivity check";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "3min";
        OnUnitActiveSec = cfg.wanWatchdog.interval;
      };
    };
  };
}
