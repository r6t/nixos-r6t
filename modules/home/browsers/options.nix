{ lib, ... }:

{
  options.mine.home.browsers = {
    enable = lib.mkEnableOption "enable desktop web browsers in home-manager";

    firefoxSync.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Configure Firefox Sync using the firefox_sync SOPS secret";
    };
  };
}
