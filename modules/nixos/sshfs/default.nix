{ lib, config, pkgs, ... }:

{

  options = {
    mine.sshfs.enable =
      lib.mkEnableOption "enable and configure sshfs";
  };

  config = lib.mkIf config.mine.sshfs.enable (import ./config.nix { inherit pkgs; });
}
