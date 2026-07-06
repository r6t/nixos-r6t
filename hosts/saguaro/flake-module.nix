{
  flake.modules.nixos.saguaro = {
    imports = [ ./configuration.nix ];
  };
}
