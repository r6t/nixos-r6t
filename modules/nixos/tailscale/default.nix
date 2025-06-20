{ lib, config, ... }: {

  options = {
    mine.tailscale.enable =
      lib.mkEnableOption "enable and configure tailscale+exit node client";
  };

  config = lib.mkIf config.mine.tailscale.enable {
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "client";
    };

    # allow tailnet traffic
    networking.firewall = {
      checkReversePath = "loose";
      trustedInterfaces = [ "tailscale0" ];
    };

    # prevent nixos rebuilds getting hung up on network manager checking tailscale interface
    networking.networkmanager.settings = {
      keyfile = {
        unmanaged-devices = "interface-name:tailscale0";
      };
    };
  };
}
