{
  flake.modules.nixos.desktop-basics = { ... }: {
    imports = [
      ../../nixos/networkmanager/options.nix
      ../../nixos/networkmanager/config.nix
      ../../nixos/sound/options.nix
      ../../nixos/sound/config.nix
    ];

    nixpkgs.config.allowUnfree = true;
  };
}
