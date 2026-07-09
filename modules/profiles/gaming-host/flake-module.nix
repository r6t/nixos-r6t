{
  flake.modules.nixos.gaming-host = { ... }: {
    imports = [
      ../../nixos/networkmanager/options.nix
      ../../nixos/networkmanager/config.nix
      ../../nixos/sound/options.nix
      ../../nixos/sound/config.nix
      ../../nixos/steam/options.nix
      ../../nixos/steam/config.nix
    ];

    nixpkgs.config.allowUnfree = true;
  };
}
