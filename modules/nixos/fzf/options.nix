{ lib, ... }:

{
  options.mine.fzf.enable =
    lib.mkEnableOption "enable fzf";
}
