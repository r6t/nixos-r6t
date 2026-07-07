{ lib, config, pkgs, ... }:

{

  options = {
    mine.printing.enable =
      lib.mkEnableOption "enable printing with brlaser + discovery";
  };

  config = lib.mkIf config.mine.printing.enable (import ./config.nix { inherit pkgs; });
}
