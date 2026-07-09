{ lib, ... }:

{
  options.mine.user.enable =
    lib.mkEnableOption "enable my user account";
}
