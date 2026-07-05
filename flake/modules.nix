{
  flake.modules = {
    homeManager = {
      alacritty = import ../modules/home/alacritty/default.nix;
      atuin = import ../modules/home/atuin/default.nix;
      fish = import ../modules/home/fish/default.nix;
      git = import ../modules/home/git/default.nix;
      nixvim = import ../modules/home/nixvim/default.nix;
      zellij = import ../modules/home/zellij/default.nix;
    };

    nixos = {
      default = import ../modules/default.nix;
    };
  };
}
