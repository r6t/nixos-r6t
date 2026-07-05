{
  flake.homeManagerModules = {
    fish = import ../modules/home/fish/default.nix;
    nixvim = import ../modules/home/nixvim/default.nix;
    zellij = import ../modules/home/zellij/default.nix;
    git = import ../modules/home/git/default.nix;
    atuin = import ../modules/home/atuin/default.nix;
    alacritty = import ../modules/home/alacritty/default.nix;
  };
}
