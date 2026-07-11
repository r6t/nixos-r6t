{ inputs, ... }:

{
  flake.modules.nixos.kde-desktop = { ... }: {
    imports = [
      inputs.self.modules.nixos.desktop-basics
      ../../nixos/bluetooth/options.nix
      ../../nixos/bluetooth/config.nix
      ../../nixos/fonts/options.nix
      ../../nixos/fonts/config.nix
      ../../nixos/kde/options.nix
      ../../nixos/kde/config.nix
      ../../nixos/printing/options.nix
      ../../nixos/printing/config.nix
      ../../nixos/v4l-utils/options.nix
      ../../nixos/v4l-utils/config.nix
    ];
  };
}
