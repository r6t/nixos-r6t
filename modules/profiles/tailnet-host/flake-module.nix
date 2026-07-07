{
  flake.modules.nixos.tailnet-host = { lib, ... }: {
    mine.tailscale.enable = lib.mkDefault true;
  };
}
