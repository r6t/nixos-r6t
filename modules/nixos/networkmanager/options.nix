{ lib, ... }:

{
  options.mine.networkmanager = {
    enable = lib.mkEnableOption "enable networkmanager";

    wifiMacAddress = lib.mkOption {
      type = lib.types.str;
      default = "stable-ssid";
      description = "NetworkManager wifi.cloned-mac-address default for new Wi-Fi connections";
    };
  };
}
