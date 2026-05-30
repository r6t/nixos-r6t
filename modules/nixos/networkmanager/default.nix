{ lib, config, ... }: {

  options = {
    mine.networkmanager.enable =
      lib.mkEnableOption "enable networkmanager";
  };

  config = lib.mkIf config.mine.networkmanager.enable {
    networking.networkmanager = {
      enable = true;
      wifi.macAddress = "stable-ssid";
      # stable-ssid: NM derives a consistent MAC per SSID using a stable hash.
      # The AP always sees the same client MAC for a given network (no Reason 9
      # deauth from MAC changing between association attempts), while the MAC
      # still differs from the hardware address and across different SSIDs.
      wifi.scanRandMacAddress = true; # keep scan-time randomization for privacy
    };
  };
}
