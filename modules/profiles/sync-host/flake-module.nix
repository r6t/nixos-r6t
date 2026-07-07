{
  flake.modules.nixos.sync-host = {
    imports = [
      ../../nixos/sshfs/config.nix
      ../../nixos/syncthing/config.nix
    ];
  };
}
