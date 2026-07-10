{ lib, pkgs, cfg, diagnosticsScript }:

{
  # Ensure iproute2 with CAKE support is available
  environment.systemPackages = [
    pkgs.iproute2
    pkgs.ethtool
    diagnosticsScript
  ];

  # Network configuration
  networking = {
    enableIPv6 = false;
    nat.enable = false;
    useNetworkd = true;
    dhcpcd.enable = false;
    nameservers = [ "127.0.0.1" ];

    interfaces = {
      ${cfg.lanInterface}.useDHCP = false;
      ${cfg.wanInterface}.useDHCP = true;
    } // lib.listToAttrs (map
      (iface: {
        name = iface;
        value.useDHCP = false;
      })
      cfg.extraInterfaces);

    firewall = {
      enable = false; # Disabled - using nftables instead
      checkReversePath = false;
    };
  };

  systemd.network.enable = true;
}
