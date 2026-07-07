{ lib, config, ... }:

{
  options.mine.direnv.enable = lib.mkEnableOption "enable direnv configuration";

  config = lib.mkIf config.mine.direnv.enable (import ./config.nix);
}
