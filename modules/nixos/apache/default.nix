{ lib, config, pkgs, ... }: {

  options = {
    mine.apache.enable =
      lib.mkEnableOption "enable apache";
  };

  config = lib.mkIf config.mine.apache.enable (import ./config.nix { inherit pkgs; });
}
