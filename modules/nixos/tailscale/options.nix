{ lib, config, ... }:
{
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
}
