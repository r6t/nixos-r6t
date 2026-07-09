{ lib, ... }:

{
  options.mine.rdfind.enable =
    lib.mkEnableOption "enable rdfind";
}
