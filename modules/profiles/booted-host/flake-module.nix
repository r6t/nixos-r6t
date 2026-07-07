{
  flake.modules.nixos.booted-host = {
    imports = [ ../../nixos/bootloader/config.nix ];
  };
}
