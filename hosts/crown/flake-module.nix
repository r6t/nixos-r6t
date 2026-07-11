{ inputs, ... }:

{
  flake.modules.nixos.crown = {
    imports = [
      inputs.self.modules.nixos.r6t-base
      inputs.self.modules.nixos.r6t-home-core
      inputs.self.modules.nixos.infra-host
      inputs.self.modules.nixos.incus-host
      inputs.self.modules.nixos.monitoring-agent
      inputs.self.modules.nixos.nfs-host
      inputs.self.modules.nixos.nvidia-container-host
      inputs.self.modules.nixos.sops-host
      inputs.self.modules.nixos.static-lan-host
      inputs.self.modules.nixos.sync-host
      inputs.self.modules.nixos.thunderbolt-host
      inputs.self.modules.nixos.zfs-host
      ./configuration.nix
    ];
  };
}
