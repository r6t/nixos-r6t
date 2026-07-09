{
  flake.modules.nixos.r6t-home-core = { lib, ... }: {
    imports = [
      ../../home/atuin/options.nix
      ../../home/atuin/config.nix
      ../../home/fish/options.nix
      ../../home/fish/config.nix
      ../../home/git/options.nix
      ../../home/git/config.nix
      ../../home/home-manager/options.nix
      ../../home/home-manager/config.nix
      ../../home/ssh/options.nix
      ../../home/ssh/config.nix
    ];

    mine.home = {
      nixvim.enable = lib.mkDefault true;
    };
  };
}
