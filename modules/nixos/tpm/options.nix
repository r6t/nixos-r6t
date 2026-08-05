{ lib, ... }:

{
  options.mine.tpm.enable =
    lib.mkEnableOption "enable tpm utilities";
}
