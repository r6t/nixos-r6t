{
  flake.modules.nixos.cgrouped-nix-builds = { lib, ... }: {
    nix.settings.use-cgroups = lib.mkDefault true;
  };
}
