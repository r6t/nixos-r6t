{ inputs, ... }:

{
  flake.modules.nixos.r6t-base = {
    imports = [
      inputs.self.modules.nixos.booted-host
      inputs.self.modules.nixos.r6t-system-core
      inputs.self.modules.nixos.tailnet-host
    ];
  };
}
