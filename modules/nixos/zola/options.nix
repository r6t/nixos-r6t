{ lib, ... }:

{
  options.mine.zola.enable =
    lib.mkEnableOption "enable zola static site generator";
}
