{ lib, ... }:

{
  options.mine.syncthing.enable = lib.mkEnableOption "enable and configure my syncthing";
}
