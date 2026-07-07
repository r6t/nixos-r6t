{ inputs, ... }:

{
  flake.modules.nixos.hedgehog = {
    imports = [
      inputs.self.modules.nixos.r6t-system-core
      inputs.self.modules.nixos.r6t-home-shell
      inputs.self.modules.nixos.gaming-host
      inputs.self.modules.nixos.nvidia-cuda-workload
      inputs.self.modules.nixos.tailnet-host
      ./configuration.nix
    ];
  };
}
