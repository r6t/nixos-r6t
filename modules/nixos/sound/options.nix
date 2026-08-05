{ lib, ... }:

{
  options.mine.sound.enable =
    lib.mkEnableOption "enable my audio";
}
