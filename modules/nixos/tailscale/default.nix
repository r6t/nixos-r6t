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

    # Automatically enable short-name resolution (ssh crown) in containers.
    # We add the tailnet suffix to the search list and tell dnsmasq to 
    # route those queries specifically to Tailscale.
    networking.search = lib.mkIf config.boot.isContainer [ "cloudforest-darter.ts.net" ];

    services.dnsmasq.settings.server = [
      "/cloudforest-darter.ts.net/100.100.100.100"
    ];

    systemd.services = {
      # For ephemeral nodes, logout on stop to ensure immediate removal from the tailnet
      tailscaled.serviceConfig.ExecStop = lib.mkIf config.mine.tailscale.ephemeral (
        pkgs.writeShellScript "tailscale-logout" ''
          ${config.services.tailscale.package}/bin/tailscale logout || true
        ''
      );

      # Explicitly run 'tailscale up' if an authKeyFile is provided.
      # This is required for headless auto-joining on first boot or relaunch.
      tailscale-autoconnect = lib.mkIf (config.mine.tailscale.authKeyFile != null) {
        description = "Automatic Tailscale login";
        after = [ "tailscaled.service" "network-online.target" ];
        wants = [ "tailscaled.service" "network-online.target" ];
        wantedBy = [ "multi-user.target" ];
        path = [ config.services.tailscale.package pkgs.gnugrep ];
        script = ''
          # Wait for tailscaled to be ready (status returns 0 or 1 when daemon is alive)
          until tailscale status >/dev/null 2>&1 || [ $? -eq 1 ]; do
            sleep 1
          done

          # Check if already authenticated
          if tailscale status | grep -q "Logged out"; then
            echo "Authenticating with authKeyFile..."
            tailscale up --authkey="$(cat ${config.mine.tailscale.authKeyFile})" ${lib.concatStringsSep " " config.services.tailscale.extraUpFlags}
          else
            echo "Already authenticated, ensuring flags are up to date..."
            tailscale up ${lib.concatStringsSep " " config.services.tailscale.extraUpFlags}
          fi
        '';
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
      };

      # All containers benefit from syncing their Tailscale name from the cloud-init seed,
      # preventing naming collisions (like -1 suffixes) and ensuring consistency.
      tailscale-set-hostname = lib.mkIf config.boot.isContainer {
        description = "Set Tailscale hostname from cloud-init seed";
        after = [ "tailscale-autoconnect.service" "tailscaled.service" "cloud-final.service" ];
        wants = [ "tailscale-autoconnect.service" ];
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
