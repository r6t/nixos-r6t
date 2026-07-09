{
  flake.modules.nixos.sync-host = {
    imports = [
      ../../nixos/sshfs/options.nix
      ../../nixos/sshfs/config.nix
      ../../nixos/syncthing/options.nix
      ../../nixos/syncthing/config.nix
    ];
  };
}
