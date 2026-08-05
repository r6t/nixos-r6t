{ lib, ... }:

{
  options = {
    mine.kde.enable =
      lib.mkEnableOption "enable and configure kde desktop";
    mine.kde.tablet =
      lib.mkEnableOption "tablet/touchscreen extras (on-screen keyboard packages)";
  };
}
