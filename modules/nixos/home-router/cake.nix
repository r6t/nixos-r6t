{ lib, pkgs, cfg }:

lib.mkIf cfg.cake.enable {
  systemd.services = {
    cake-qos-egress = {
      description = "CAKE QoS egress (upload) shaping on ${cfg.wanInterface}";
      after = [ "systemd-networkd.service" "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        # Wait for interface to be ready
        for i in {1..30}; do
          if ${pkgs.iproute2}/bin/ip link show ${cfg.wanInterface} &>/dev/null; then
            break
          fi
          sleep 1
        done

        # Remove existing qdisc (ignore errors if none exists)
        ${pkgs.iproute2}/bin/tc qdisc del dev ${cfg.wanInterface} root 2>/dev/null || true

        # Apply CAKE to WAN egress (upload)
        ${pkgs.iproute2}/bin/tc qdisc add dev ${cfg.wanInterface} root cake \
          bandwidth ${toString cfg.cake.uploadRate}kbit \
          ${lib.concatStringsSep " " cfg.cake.extraOptions} \
          ethernet \
          overhead ${toString cfg.cake.overhead}

        echo "CAKE egress (upload) applied to ${cfg.wanInterface}: ${toString cfg.cake.uploadRate} kbit"
      '';

      preStop = ''
        # Restore default qdisc on service stop
        ${pkgs.iproute2}/bin/tc qdisc del dev ${cfg.wanInterface} root 2>/dev/null || true
        echo "CAKE egress removed from ${cfg.wanInterface}"
      '';
    };

    cake-qos-ingress = {
      description = "CAKE QoS ingress (download) shaping on ${cfg.wanInterface} via IFB";
      after = [ "cake-qos-egress.service" ];
      wants = [ "cake-qos-egress.service" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      script = ''
        # Create IFB (Intermediate Functional Block) interface for ingress shaping
        ${pkgs.iproute2}/bin/ip link add ifb4${cfg.wanInterface} type ifb 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip link set ifb4${cfg.wanInterface} up

        # Redirect ingress traffic from WAN to IFB
        ${pkgs.iproute2}/bin/tc qdisc add dev ${cfg.wanInterface} handle ffff: ingress 2>/dev/null || true
        ${pkgs.iproute2}/bin/tc filter add dev ${cfg.wanInterface} parent ffff: \
          protocol all u32 match u32 0 0 \
          action mirred egress redirect dev ifb4${cfg.wanInterface}

        # Apply CAKE to IFB egress (which handles WAN ingress/download)
        ${pkgs.iproute2}/bin/tc qdisc del dev ifb4${cfg.wanInterface} root 2>/dev/null || true
        ${pkgs.iproute2}/bin/tc qdisc add dev ifb4${cfg.wanInterface} root cake \
          bandwidth ${toString cfg.cake.downloadRate}kbit \
          ${lib.concatStringsSep " " (lib.filter (opt: opt != "ack-filter") cfg.cake.extraOptions)} \
          ethernet \
          overhead ${toString cfg.cake.overhead}

        echo "CAKE ingress (download) applied to ${cfg.wanInterface} via ifb4${cfg.wanInterface}: ${toString cfg.cake.downloadRate} kbit"
      '';

      preStop = ''
        # Clean up ingress shaping
        ${pkgs.iproute2}/bin/tc qdisc del dev ${cfg.wanInterface} ingress 2>/dev/null || true
        ${pkgs.iproute2}/bin/tc qdisc del dev ifb4${cfg.wanInterface} root 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip link set ifb4${cfg.wanInterface} down 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip link del ifb4${cfg.wanInterface} 2>/dev/null || true
        echo "CAKE ingress removed from ${cfg.wanInterface}"
      '';
    };
  };
}
