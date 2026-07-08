{
  flake.modules.nixos.gaming-host = { ... }: {
    imports = [
      ../../nixos/networkmanager/config.nix
      ../../nixos/sound/config.nix
      ../../nixos/steam/config.nix
    ];

    nixpkgs.config.allowUnfree = true;
  };
}
