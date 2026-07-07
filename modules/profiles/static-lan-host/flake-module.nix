{
  flake.modules.nixos.static-lan-host = { lib, ... }: {
    networking = {
      useNetworkd = lib.mkDefault true;
      nameservers = lib.mkDefault [ "192.168.6.1" ];
      defaultGateway.address = lib.mkDefault "192.168.6.1";
    };

    services.resolved = {
      enable = lib.mkDefault true;
      settings.Resolve.Domains = lib.mkDefault [ "~." ];
    };
  };
}
