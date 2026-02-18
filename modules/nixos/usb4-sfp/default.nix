{ lib, config, pkgs, ... }: {
  options = {
    mine.usb4-sfp.enable =
      lib.mkEnableOption "USB4 SFP+ 10G ixgbe adapter support";
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
          DevicePath = "*-pci-*:00.0"; # first port
        };
        linkConfig.Name = "ixgbe0";
      };
      "11-ixgbe1" = {
        matchConfig = {
          Driver = "ixgbe";
          DevicePath = "*-pci-*:00.1"; # second port
        };
        linkConfig.Name = "ixgbe1";
      };
    };

    # Troubleshooting ixgbe intermittent freeze
    # Comprehensive ethtool settings service
    systemd.services.ixgbe-force-settings = {
      description = "Apply comprehensive ixgbe ethtool settings";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      path = [ pkgs.ethtool pkgs.coreutils pkgs.iproute2 ];
      script = ''
        # Wait for link stability
        sleep 3
        
        # Only proceed if interface exists
        if ip link show ixgbe0 &>/dev/null; then
          echo "Applying ixgbe0 settings..."
          
          # Disable pause frames (flow control)
          ethtool -A ixgbe0 autoneg off rx off tx off || true
          
          # Disable offloads including LRO
          ethtool -K ixgbe0 gso off tso off gro off lro off || true
          
          # Disable interrupt coalescing for low latency
          ethtool -C ixgbe0 rx-usecs 0 tx-usecs 0 || true
          
          echo "ixgbe0 settings applied successfully"
        else
          echo "ixgbe0 not present, skipping"
        fi
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      wantedBy = [ "multi-user.target" ];
    };

    # For hotplug: udev rule triggers the same service when device appears
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="net", KERNEL=="ixgbe0", RUN+="${pkgs.systemd}/bin/systemctl restart ixgbe-force-settings.service"
    '';
  };
}
