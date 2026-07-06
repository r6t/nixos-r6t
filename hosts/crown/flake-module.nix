{
  flake.modules.nixos.crown = {
    imports = [ ./configuration.nix ];
  };
}
