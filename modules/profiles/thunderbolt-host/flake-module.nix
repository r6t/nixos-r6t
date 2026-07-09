{
  flake.modules.nixos.thunderbolt-host = {
    imports = [
      ../../nixos/bolt/options.nix
      ../../nixos/bolt/config.nix
    ];
  };
}
