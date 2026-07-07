{
  flake.modules.nixos.r6t-home-core = { lib, ... }: {
    imports = [
      ../../home/atuin/config.nix
      ../../home/fish/config.nix
      ../../home/git/config.nix
      ../../home/home-manager/config.nix
      ../../home/ssh/config.nix
    ];

    mine.home = {
      nixvim.enable = lib.mkDefault true;
    };
  };
}
