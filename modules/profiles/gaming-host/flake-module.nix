{ inputs, ... }:

{
  flake.modules.nixos.gaming-host = { ... }: {
    imports = [
      inputs.self.modules.nixos.desktop-basics
      ../../nixos/steam/options.nix
      ../../nixos/steam/config.nix
    ];
  };
}
