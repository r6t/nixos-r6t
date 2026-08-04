{ config, ... }:

{
  networking.networkmanager = {
    enable = true;
    wifi.macAddress = config.mine.networkmanager.wifiMacAddress;
    # stable-ssid: NM derives a consistent MAC per SSID using a stable hash.
    # The AP always sees the same client MAC for a given network (no Reason 9
    # deauth from MAC changing between association attempts), while the MAC
    # still differs from the hardware address and across different SSIDs.
    #
    # IMPORTANT: the global [connection] default only applies to NEW connections
    # where the per-profile cloned-mac-address is unset. Existing connections
    # created before this setting was added may not pick it up. Fix with:
    #   nmcli connection modify <name> 802-11-wireless.cloned-mac-address stable-ssid
    wifi.scanRandMacAddress = true; # keep scan-time randomization for privacy
  };
}
