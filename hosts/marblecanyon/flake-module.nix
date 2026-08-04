{ inputs, ... }:

{
  nixosHostSpecialArgs.marblecanyon.userConfig = {
    username = "admin";
    homeDirectory = "/home/admin";
  };

  flake.modules.nixos.marblecanyon = {
    imports = [
      inputs.self.modules.nixos.booted-host
      inputs.self.modules.nixos.system-core
      inputs.self.modules.nixos.home-shell
      inputs.self.modules.nixos.kde-desktop-core
      inputs.self.modules.nixos.desktop-home-core
      inputs.self.modules.nixos.laptop-workstation
      inputs.self.modules.nixos.tailnet-host
      ./configuration.nix
    ];
  };
}
