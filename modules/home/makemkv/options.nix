{ lib, ... }:

{
  options.mine.home.makemkv.enable =
    lib.mkEnableOption "enable makemkv";
}
