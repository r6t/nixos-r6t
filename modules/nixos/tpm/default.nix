{ lib, config, pkgs, ... }: {

  options = {
    mine.tpm.enable =
      lib.mkEnableOption "enable tpm utilities";
  };

  config = lib.mkIf config.mine.tpm.enable (import ./config.nix { inherit pkgs; });
}
