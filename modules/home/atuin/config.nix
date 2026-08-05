{ userConfig, isNixOS ? true, ... }:

let
  wrapHome = import ../../lib/mkPortableHomeConfig.nix { inherit isNixOS userConfig; };
in
wrapHome {
  programs.atuin = {
    enable = true;
    # causes bind -k warning on fish >4.1
    # atuin 18.8.0 + fish 4.1.2 still throwing -k warnings
    enableFishIntegration = true;
    flags = [ "--disable-up-arrow" ];
  };
}
