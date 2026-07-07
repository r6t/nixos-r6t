{
  flake.modules.nixos.nix-build-throttle = { lib, ... }: {
    systemd.services.nix-daemon.serviceConfig.CPUQuota = lib.mkDefault "800%";
  };
}
