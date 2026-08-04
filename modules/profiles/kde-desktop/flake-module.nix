{ inputs, ... }:

{
  flake.modules.nixos.kde-desktop = { ... }: {
    imports = [
      inputs.self.modules.nixos.kde-desktop-core
      ../../nixos/printing/options.nix
      ../../nixos/printing/config.nix
    ];
  };
}
