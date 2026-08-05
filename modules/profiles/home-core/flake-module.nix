{ inputs, ... }:

{
  flake.modules.nixos.home-core = { lib, ... }: {
    imports = [
      inputs.home-manager.nixosModules.home-manager
      ../../home/atuin/options.nix
      ../../home/atuin/config.nix
      ../../home/fish/options.nix
      ../../home/fish/config.nix
      ../../home/git/options.nix
      ../../home/git/config.nix
      ../../home/home-manager/options.nix
      ../../home/home-manager/config.nix
      ../../home/nixvim/default.nix
    ];

    mine.home = {
      nixvim.enable = lib.mkDefault true;
    };
  };
}
