{
  flake.modules.nixos.static-lan-host = { lib, ... }: {
    networking.useNetworkd = lib.mkDefault true;

    services.resolved = {
      enable = lib.mkDefault true;
      settings.Resolve.Domains = lib.mkDefault [ "~." ];
    };
  };
}
