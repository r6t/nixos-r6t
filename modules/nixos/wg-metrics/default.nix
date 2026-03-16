{ lib, config, pkgs, ... }:

let
  cfg = config.mine.wg-metrics;
  textfileDir = "/var/lib/prometheus-node-exporter/textfile";

  # Instances to poll — names of incus containers running WireGuard.
  # Determined by the instance_map: anything mapping to tailnet-exit,
  # plus any instance named tailnet-exit itself.
  pollerScript = pkgs.writeShellScript "wg-metrics-collector" ''
    set -euo pipefail

    INCUS="${pkgs.incus}/bin/incus"
    OUT_DIR="${textfileDir}"
    TMP="$OUT_DIR/.wg_metrics.$$.prom"

    mkdir -p "$OUT_DIR"

    # Discover running exit node containers.
    # Match instances whose image alias is tailnet-exit (via instance_map.json)
    # or whose name is tailnet-exit.
    mapfile -t running < <($INCUS list type=container status=running -c n --format csv 2>/dev/null)

    MAP_FILE="${cfg.instanceMapFile}"
    declare -A IMAGE_MAP
    if [ -f "$MAP_FILE" ]; then
      while IFS= read -r line; do
        key=$(echo "$line" | ${pkgs.jq}/bin/jq -r '.key')
        val=$(echo "$line" | ${pkgs.jq}/bin/jq -r '.value')
        IMAGE_MAP["$key"]="$val"
      done < <(${pkgs.jq}/bin/jq -c 'to_entries[] | {key: .key, value: .value}' "$MAP_FILE")
    fi

    # Collect metrics into temp file
    cat /dev/null > "$TMP"

    for name in "''${running[@]}"; do
      [ -z "$name" ] && continue

      # Resolve image alias
      image="''${IMAGE_MAP[$name]:-$name}"
      [ "$image" != "tailnet-exit" ] && continue

      # Run wg show inside the container
      dump=$($INCUS exec "$name" -- wg show all dump 2>/dev/null) || continue

      # wg show all dump format (tab-separated):
      #   Interface line (5 fields): iface private_key public_key listen_port fwmark
      #   Peer line     (9 fields): iface public_key preshared_key endpoint allowed_ips latest_handshake transfer_rx transfer_tx persistent_keepalive
      while IFS=$'\t' read -r iface f2 f3 f4 f5 f6 f7 f8 f9; do
        # Peer lines have 9 fields; interface lines leave f6-f9 empty
        [ -z "$f6" ] && continue

        pub_key="$f2"
        handshake="$f6"
        rx="$f7"
        tx="$f8"
        short_key="''${pub_key:0:8}"

        {
          echo "wg_peer_last_handshake_seconds{instance=\"$name\",interface=\"$iface\",public_key=\"$short_key\"} $handshake"
          echo "wg_peer_transfer_rx_bytes{instance=\"$name\",interface=\"$iface\",public_key=\"$short_key\"} $rx"
          echo "wg_peer_transfer_tx_bytes{instance=\"$name\",interface=\"$iface\",public_key=\"$short_key\"} $tx"
        } >> "$TMP"
      done <<< "$dump"
    done

    # Atomic replace
    mv "$TMP" "$OUT_DIR/wg_metrics.prom"
  '';
in
{
  options.mine.wg-metrics = {
    enable = lib.mkEnableOption "WireGuard metrics collection from incus exit node containers";

    interval = lib.mkOption {
      type = lib.types.str;
      default = "300s";
      description = "How often to poll WireGuard stats (systemd OnUnitActiveSec format)";
    };

    instanceMapFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to instance_map.json that maps incus instance names to image aliases";
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable textfile collector on node-exporter
    services.prometheus.exporters.node = {
      extraFlags = [ "--collector.textfile.directory=${textfileDir}" ];
    };

    systemd = {
      tmpfiles.rules = [
        "d ${textfileDir} 0755 root root - -"
      ];

      services.wg-metrics-collector = {
        description = "Collect WireGuard metrics from incus exit node containers";
        after = [ "incus.service" ];
        wants = [ "incus.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pollerScript;
        };
      };

      timers.wg-metrics-collector = {
        description = "Periodic WireGuard metrics collection";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "2min";
          OnUnitActiveSec = cfg.interval;
        };
      };
    };
  };
}
