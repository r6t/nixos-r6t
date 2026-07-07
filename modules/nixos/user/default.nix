{ inputs, lib, config, pkgs, ... }:

{
  options = {
    mine.user.enable =
      lib.mkEnableOption "enable my user account";
  };

  config = lib.mkIf config.mine.user.enable (import ./config.nix { inherit inputs lib pkgs; });
}
