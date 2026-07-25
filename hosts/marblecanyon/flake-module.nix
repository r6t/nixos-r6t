{ inputs, ... }:

{
  flake.modules.nixos.marblecanyon = {
    imports = [
      inputs.self.modules.nixos.r6t-base
      inputs.self.modules.nixos.r6t-home-shell
      inputs.self.modules.nixos.kde-workstation
      inputs.self.modules.nixos.laptop-workstation
      ./configuration.nix
    ];
  };
}
