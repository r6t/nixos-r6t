{ lib, config, ... }: {

  options = {
    mine.tailscale.enable =
      lib.mkEnableOption "enable tailscale";
  };

  config = lib.mkIf config.mine.tailscale.enable {
    services.tailscale = {
      enable = true;
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
