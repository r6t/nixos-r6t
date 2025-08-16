{ lib, config, ... }: {

  options = {
    mine.tailscale.enable =
      lib.mkEnableOption "enable and configure tailscale+exit node client";
    # prob going to delete this module and just manage tailscale in host def alongside networking
  };

  config = lib.mkIf config.mine.tailscale.enable {
    services.tailscale = {
      enable = true;
      #      useRoutingFeatures = "client"; # exit-node module mkForces this value = "server"
    };

    # allow tailnet traffic
    networking.firewall = {
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
