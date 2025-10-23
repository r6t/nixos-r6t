{ lib, config, pkgs, ... }: {
  options = {
    mine.usb4-sfp.enable =
      lib.mkEnableOption "USB4 SFP+ 10G adapter support";
  };
  config = lib.mkIf config.mine.usb4-sfp.enable {
    boot.kernelModules = [ "ixgbe" ];
    boot.extraModprobeConfig = ''
      options ixgbe allow_unsupported_sfp=1
    '';

    systemd.network.links = {
      "10-ixgbe0" = {
        matchConfig = {
          Driver = "ixgbe";
          DevicePath = "*-pci-*:00.0"; # first port function
        };
        linkConfig.Name = "ixgbe0";
      };
      "11-ixgbe1" = {
        matchConfig = {
          Driver = "ixgbe";
          DevicePath = "*-pci-*:00.1"; # second port function
        };
        linkConfig.Name = "ixgbe1";
      };
    };

    # Troubleshooting ixgbe intermittent freeze
    # This systemd service will forcefully apply the correct ethtool settings after
    # the network is brought online by NetworkManager.
    systemd.services.ixgbe-force-settings = {
      description = "Forcefully apply final ethtool settings for ixgbe0";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      path = [ pkgs.ethtool pkgs.coreutils ];
      script = ''
        # Wait a moment to ensure the link is fully stable.
        sleep 2
        # Apply the settings directly.
        ethtool -A ixgbe0 autoneg off rx off tx off
        ethtool -K ixgbe0 gso off tso off gro off
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
