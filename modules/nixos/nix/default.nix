{ inputs, lib, config, ... }:

{

  options = {
    mine.nix.enable = lib.mkEnableOption "enable my usual nix config";
  };

  config = lib.mkIf config.mine.nix.enable (import ./config.nix { inherit inputs lib config; });
}
