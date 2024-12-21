{ lib, config, ... }: {

  options = {
    mine.tailscale.enable =
      lib.mkEnableOption "enable and configure tailscale";
  };

  config = lib.mkIf config.mine.tailscale.enable {
    services.tailscale.enable = true;

    # prevent nixos rebuilds getting hung up on network manager checking tailscale interface
    networking.networkmanager.settings = {
      keyfile = {
        unmanaged-devices = "interface-name:tailscale0";
      };
    };
  };
}
