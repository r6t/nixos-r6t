{ inputs, ... }:

{
  flake.modules.nixos.office-desk = {
    imports = [
      inputs.self.modules.nixos.thunderbolt-host
    ];
  };
}
