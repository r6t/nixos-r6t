{ lib, ... }:

{
  options.mine.alloy = {
    enable = lib.mkEnableOption "enable alloy service";

    lokiUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://localhost:3100/loki/api/v1/push";
      description = "Loki push API URL. Override for hosts that reach Loki over LAN instead of tailnet.";
      example = "https://loki.example.com/loki/api/v1/push";
    };

    lokiInsecureTls = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Skip TLS certificate verification for Loki. Use when pushing to an IP address where the cert won't match.";
    };

    syslogListen = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Listen for UDP syslog on port 514 and forward to Loki. Enable on the host closest to network devices sending syslog.";
    };
  };
}
