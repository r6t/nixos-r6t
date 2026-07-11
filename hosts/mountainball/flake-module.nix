{ inputs, ... }:

{
  flake.modules.nixos.mountainball = {
    imports = [
      inputs.self.modules.nixos.r6t-base
      inputs.self.modules.nixos.r6t-home-shell
      inputs.self.modules.nixos.gaming-host
      inputs.self.modules.nixos.kde-workstation
      inputs.self.modules.nixos.laptop-workstation
      inputs.self.modules.nixos.monitoring-agent
      inputs.self.modules.nixos.nfs-host
      inputs.self.modules.nixos.nix-build-throttle
      inputs.self.modules.nixos.office-desk
      inputs.self.modules.nixos.sops-host
      inputs.self.modules.nixos.sync-host
      ./configuration.nix
    ];
  };
}
