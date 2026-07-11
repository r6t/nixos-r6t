{ inputs, ... }:

{
  flake.modules.nixos.r6t-booted-system = {
    imports = [
      inputs.self.modules.nixos.booted-host
      inputs.self.modules.nixos.r6t-system-core
    ];
  };
}
