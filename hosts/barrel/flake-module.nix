{ inputs, ... }:

{
  flake.modules.nixos.barrel = {
    imports = [
      inputs.self.modules.nixos.r6t-base
      inputs.self.modules.nixos.r6t-home-core
      inputs.self.modules.nixos.infra-host
      inputs.self.modules.nixos.sops-host
      inputs.self.modules.nixos.static-lan-host
      inputs.self.modules.nixos.zfs-host
      ./configuration.nix
    ];
  };
}
