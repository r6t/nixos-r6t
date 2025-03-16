{ lib, config, pkgs, ... }: {

  options = {
    mine.tpm.enable =
      lib.mkEnableOption "enable tpm utilities";
  };

  config = lib.mkIf config.mine.tpm.enable {
    environment.systemPackages = with pkgs; [
      clevis
      tpm2-tools
    ];
  };
}
