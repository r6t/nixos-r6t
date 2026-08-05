{ inputs, ... }:

{
  flake.modules.nixos.r6t-system-core = {
    imports = [
      inputs.self.modules.nixos.system-core
    ];
  };
}
