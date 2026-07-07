{
  flake.modules.nixos.thunderbolt-host = {
    imports = [ ../../nixos/bolt/config.nix ];
  };
}
