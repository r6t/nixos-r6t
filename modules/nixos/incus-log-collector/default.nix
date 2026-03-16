{ lib, config, pkgs, ... }:

let
  cfg = config.mine.incus-log-collector;
  logDir = "/var/log/incus-journals";

  # Script that manages journal forwarders for all running incus containers.
  # Starts a background journalctl process per container, writing JSON to logDir.
  # Runs as a long-lived service, polling for new/removed containers.
  collectorScript = pkgs.writeShellScript "incus-log-collector" ''
    set -euo pipefail

    LOG_DIR="${logDir}"
    INCUS="${pkgs.incus}/bin/incus"
    POLL_INTERVAL=30
    declare -A PIDS

    mkdir -p "$LOG_DIR"

    cleanup() {
      echo "Stopping all journal forwarders..."
      for name in "''${!PIDS[@]}"; do
        kill "''${PIDS[$name]}" 2>/dev/null || true
      done
      exit 0
    }
    trap cleanup SIGTERM SIGINT

    start_forwarder() {
      local name="$1"
      local logfile="$LOG_DIR/$name.json"

      $INCUS exec "$name" -- journalctl --follow --output=json --no-tail 2>/dev/null \
        >> "$logfile" &
      PIDS["$name"]=$!
      echo "Started journal forwarder for $name (pid ''${PIDS[$name]})"
    }

    stop_forwarder() {
      local name="$1"
      if [ -n "''${PIDS[$name]+x}" ]; then
        kill "''${PIDS[$name]}" 2>/dev/null || true
        unset PIDS["$name"]
        echo "Stopped journal forwarder for $name"
      fi
    }

    while true; do
      # Get currently running containers
      running=$($INCUS list -c n --format csv status=RUNNING 2>/dev/null || true)

      # Start forwarders for new containers
      while IFS= read -r name; do
        [ -z "$name" ] && continue
        if [ -z "''${PIDS[$name]+x}" ]; then
          start_forwarder "$name"
        else
          # Check if forwarder process is still alive
          if ! kill -0 "''${PIDS[$name]}" 2>/dev/null; then
            echo "Forwarder for $name died, restarting..."
            start_forwarder "$name"
          fi
        fi
      done <<< "$running"

      # Stop forwarders for containers that are no longer running
      for name in "''${!PIDS[@]}"; do
        if ! echo "$running" | grep -qx "$name"; then
          stop_forwarder "$name"
        fi
      done

      sleep "$POLL_INTERVAL"
    done
  '';
in
{
  options.mine.incus-log-collector = {
    enable = lib.mkEnableOption "collect journald logs from incus containers";
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${logDir} 0755 root root - -"
    ];

    systemd.services.incus-log-collector = {
      description = "Collect journald logs from running incus containers";
      after = [ "incus.service" ];
      wants = [ "incus.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = collectorScript;
        Restart = "always";
        RestartSec = 10;
        # Rotate log files to prevent unbounded growth
        LogsDirectory = "incus-journals";
      };
    };

    # Logrotate to manage the JSON log files
    services.logrotate.settings."incus-journals" = {
      files = "${logDir}/*.json";
      frequency = "daily";
      rotate = 7;
      compress = true;
      missingok = true;
      notifempty = true;
      copytruncate = true;
    };
  };
}
