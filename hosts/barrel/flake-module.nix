{
  flake.modules.nixos.barrel = {
    imports = [ ./configuration.nix ];
  };
}
