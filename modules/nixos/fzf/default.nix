{ lib, config, pkgs, ... }:

{

  options = {
    mine.fzf.enable =
      lib.mkEnableOption "enable fzf";
  };

  config = lib.mkIf config.mine.fzf.enable (import ./config.nix { inherit pkgs; });
}
