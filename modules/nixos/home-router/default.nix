{ lib, config, pkgs, ... }:

let
  cfg = config.mine.home-router;
in
{
  options.mine.home-router = {
    enable = lib.mkEnableOption "home router with CAKE QoS for bufferbloat mitigation";

    wanInterface = lib.mkOption {
      type = lib.types.str;
      default = "enp101s0";
      description = "WAN interface name";
    };

    lanInterface = lib.mkOption {
      type = lib.types.str;
      default = "enp100s0";
      description = "LAN interface name";
    };

    cake = {
      enable = lib.mkEnableOption "CAKE QoS for bufferbloat mitigation" // { default = true; };

      downloadRate = lib.mkOption {
        type = lib.types.int;
        default = 970000; # kbit - 970 Mbps for gigabit fiber
        description = "Download rate limit in kbit (leave ~3% headroom for queue management)";
      };

      uploadRate = lib.mkOption {
        type = lib.types.int;
        default = 970000; # kbit - 970 Mbps for gigabit fiber
        description = "Upload rate limit in kbit (leave ~3% headroom for queue management)";
      };

      overhead = lib.mkOption {
        type = lib.types.int;
        default = 18; # Ethernet framing only (no PPPoE)
        description = "Link layer overhead in bytes (18 for fiber without PPPoE, 26 with PPPoE)";
      };

      extraOptions = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "diffserv4" # 4-tier traffic prioritization (better for gaming)
          "dual-srchost" # Fair queuing per source IP
          "nat" # Recognize NATed devices individually
          "nowash" # Don't reclassify DSCP markings
          "ack-filter" # Filter redundant ACKs during upload saturation
        ];
        description = "Additional CAKE qdisc options";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Load required kernel modules
    boot.kernelModules = lib.mkIf cfg.cake.enable [ "sch_cake" "ifb" "act_mirred" ];

    # Ensure iproute2 with CAKE support is available
    environment.systemPackages = with pkgs; [
      iproute2
      ethtool
    ];

    systemd.services = lib.mkIf cfg.cake.enable {
      # Service 1: Apply CAKE to egress (upload/WAN transmit)
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

      # Service 2: Apply CAKE to ingress (download/WAN receive) via IFB
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
  };
}
