{ inputs, ... }:

{
  flake.modules.nixos.saguaro = {
    imports = [
      inputs.self.modules.nixos.r6t-booted-system
      inputs.self.modules.nixos.r6t-home-core
      inputs.self.modules.nixos.infra-host
      inputs.self.modules.nixos.incus-host
      inputs.self.modules.nixos.router
      inputs.self.modules.nixos.sops-host
      inputs.self.modules.nixos.thunderbolt-host
      ./configuration.nix
    ];
  };
}
