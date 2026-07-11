{ inputs, ... }:

{
  flake.modules.nixos.goldenball = {
    imports = [
      inputs.self.modules.nixos.r6t-base
      inputs.self.modules.nixos.r6t-home-shell
      inputs.self.modules.nixos.gaming-host
      inputs.self.modules.nixos.kde-workstation
      inputs.self.modules.nixos.laptop-workstation
      inputs.self.modules.nixos.nfs-host
      inputs.self.modules.nixos.office-desk
      inputs.self.modules.nixos.sops-host
      inputs.self.modules.nixos.sync-host
      ./configuration.nix
    ];
  };
}
