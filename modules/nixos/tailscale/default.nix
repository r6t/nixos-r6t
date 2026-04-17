{ lib, config, ... }: {

  options = {
    mine.tailscale.enable =
      lib.mkEnableOption "enable tailscale";

    mine.tailscale.authKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Path to a file containing a Tailscale auth key.
        When set, tailscale auto-connects on boot using this key.
        Use an ephemeral + reusable key for containers that relaunch frequently.
        The file is bind-mounted into the container via the incus profile.
      '';
    };
  };

  config = lib.mkIf config.mine.tailscale.enable {
    services.tailscale = {
      enable = true;
      inherit (config.mine.tailscale) authKeyFile;
      # Don't let tailscale overwrite resolv.conf — DNS is managed by the
      # host's own resolver (dnsmasq in containers, resolved on hosts).
      # MagicDNS forwarding is configured separately where needed.
      extraDaemonFlags = [ "--accept-dns=false" ];
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
