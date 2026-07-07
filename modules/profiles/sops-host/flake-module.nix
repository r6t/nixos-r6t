{
  flake.modules.nixos.sops-host = { lib, ... }: {
    mine.sops.enable = lib.mkDefault true;
  };
}
