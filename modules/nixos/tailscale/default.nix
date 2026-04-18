{ lib, config, pkgs, ... }: {
  options.mine.tailscale = {
    enable = lib.mkEnableOption "enable tailscale";

    authKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Path to a file containing a Tailscale auth key.
        When set, tailscale auto-connects on boot using this key.
        Use an ephemeral + reusable key for containers that relaunch frequently.
        The file is bind-mounted into the container via the incus profile.
      '';
    };

    ephemeral = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Mark the tailscale node as ephemeral (deleted when it goes offline)";
    };

    acceptDns = lib.mkOption {
      type = lib.types.bool;
      default = !config.boot.isContainer;
      description = "Accept DNS configuration from Tailscale. Defaults to false in containers to preserve local dnsmasq pattern.";
    };

    extraUpFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra flags to pass to 'tailscale up'";
    };

    magicDnsDomain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = if config.boot.isContainer then "ts.net" else null;
      example = "ts.net";
      description = "Optional MagicDNS domain to forward via local dnsmasq (split-DNS). Defaults to 'ts.net' in containers.";
    };
  };

  config = lib.mkIf config.mine.tailscale.enable {
    services.tailscale = {
      enable = true;
      inherit (config.mine.tailscale) authKeyFile;
      extraUpFlags =
        config.mine.tailscale.extraUpFlags
        ++ (lib.optionals config.mine.tailscale.ephemeral [ "--ephemeral" ])
        ++ [ "--accept-dns=${if config.mine.tailscale.acceptDns then "true" else "false"}" ];
    };

    # Split-DNS for MagicDNS names via local dnsmasq
    services.dnsmasq.settings.server = lib.mkIf (config.mine.tailscale.magicDnsDomain != null) [
      "/${config.mine.tailscale.magicDnsDomain}/100.100.100.100"
    ];

    # For ephemeral nodes, logout on stop to ensure immediate removal from the tailnet
    systemd.services.tailscaled.serviceConfig.ExecStop = lib.mkIf config.mine.tailscale.ephemeral (
      pkgs.writeShellScript "tailscale-logout" ''
        ${config.services.tailscale.package}/bin/tailscale logout || true
      ''
    );

    # All containers benefit from syncing their Tailscale name from the cloud-init seed,
    # preventing naming collisions (like -1 suffixes) and ensuring consistency.
    systemd.services.tailscale-set-hostname = lib.mkIf config.boot.isContainer {
      description = "Set Tailscale hostname from cloud-init seed";
      after = [ "tailscaled.service" "cloud-final.service" ];
      wants = [ "tailscaled.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ config.services.tailscale.package ];
      script = ''
        SEED="/var/lib/cloud/seed/nocloud/meta-data"
        if [ -f "$SEED" ]; then
          NAME=$(${pkgs.gnugrep}/bin/grep '^local-hostname:' "$SEED" | ${pkgs.coreutils}/bin/cut -d' ' -f2)
          if [ -n "$NAME" ]; then
            echo "Setting tailscale hostname to $NAME"
            tailscale set --hostname="$NAME"
            exit 0
          fi
        fi
        echo "WARNING: Could not read hostname from $SEED, skipping"
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };

    networking = {
      # allow tailnet traffic
      firewall.trustedInterfaces = [ "tailscale0" ];
      # prevent nixos rebuilds getting hung up on network manager checking tailscale interface
      networkmanager.settings = {
        keyfile = {
          unmanaged-devices = "interface-name:tailscale0";
        };
      };
    };
  };
}
