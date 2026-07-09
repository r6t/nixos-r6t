{ inputs, ... }:

{
  flake.modules.nixos.office-desk = {
    imports = [
      inputs.self.modules.nixos.thunderbolt-host
      ../../nixos/usb4-sfp/options.nix
      ../../nixos/usb4-sfp/config.nix
    ];
  };
}
