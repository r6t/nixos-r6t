{ inputs, ... }:

{
  flake.modules.nixos.r6t-base = {
    imports = [
      inputs.self.modules.nixos.r6t-booted-system
      inputs.self.modules.nixos.tailnet-host
    ];
  };
}
