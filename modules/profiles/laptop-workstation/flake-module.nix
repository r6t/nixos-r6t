{
  flake.modules.nixos.laptop-workstation = { lib, ... }: {
    boot.loader.systemd-boot.configurationLimit = lib.mkOverride 900 3;
    services.fprintd.enable = lib.mkOverride 900 false;
  };
}
