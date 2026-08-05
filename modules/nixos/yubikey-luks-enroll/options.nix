{ lib, ... }:

{
  options.mine.yubikey-luks-enroll.enable =
    lib.mkEnableOption "enable YubiKey HMAC-SHA1 LUKS enrollment tool";
}
