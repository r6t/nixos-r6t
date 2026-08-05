{ inputs, ... }:

{
  flake.modules.nixos.kde-workstation = { ... }: {
    imports = [
      inputs.self.modules.nixos.kde-desktop
      inputs.self.modules.nixos.r6t-desktop-app-suite
    ];
  };
}
