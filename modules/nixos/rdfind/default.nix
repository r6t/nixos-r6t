{ lib, config, pkgs, ... }: {

  options = {
    mine.rdfind.enable =
      lib.mkEnableOption "enable rdfind";
  };

  config = lib.mkIf config.mine.rdfind.enable (import ./config.nix { inherit pkgs; });
}
