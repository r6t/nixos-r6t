{ inputs, ... }:

{
  flake.modules.nixos.saguaro = {
    imports = [
      inputs.self.modules.nixos.r6t-system-core
      inputs.self.modules.nixos.r6t-home-core
      inputs.self.modules.nixos.booted-host
      inputs.self.modules.nixos.infra-host
      inputs.self.modules.nixos.incus-host
      inputs.self.modules.nixos.monitoring-agent
      inputs.self.modules.nixos.router
      inputs.self.modules.nixos.sops-host
      inputs.self.modules.nixos.thunderbolt-host
      ./configuration.nix
    ];
  };
}
