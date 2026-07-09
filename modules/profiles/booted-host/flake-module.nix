{
  flake.modules.nixos.booted-host = {
    imports = [
      ../../nixos/bootloader/options.nix
      ../../nixos/bootloader/config.nix
    ];
  };
}
