{ inputs, ... }:

let
  # Stable compatibility API for downstream flakes. Keep these names available
  # even if the internal module layout moves toward dendritic feature modules.
  portableHomeManagerModules = {
    fish = import ../modules/home/fish/default.nix;
    nixvim = import ../modules/home/nixvim/default.nix;
    zellij = import ../modules/home/zellij/default.nix;
    git = import ../modules/home/git/default.nix;
    atuin = import ../modules/home/atuin/default.nix;
    alacritty = import ../modules/home/alacritty/default.nix;
  };
in
{
  flake.homeManagerModules = portableHomeManagerModules // {
    default = {
      imports = [
        inputs.nixvim.homeModules.nixvim
      ] ++ builtins.attrValues portableHomeManagerModules;
    };
  };
}
