{
  flake.modules.nixos.infra-networkd-journal = { lib, ... }: {
    services.journald.extraConfig = lib.mkDefault "SystemMaxUse=500M";
    systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;
  };
}
