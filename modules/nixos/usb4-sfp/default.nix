{ lib, config, pkgs, ... }: {
  options = {
    mine.usb4-sfp.enable =
      lib.mkEnableOption "USB4 SFP+ 10G ixgbe adapter support";
  };
  config = lib.mkIf config.mine.usb4-sfp.enable {
    boot.extraModprobeConfig = ''
      # allow_unsupported_sfp: required for many SFP+ modules not on Intel's allowlist
      options ixgbe allow_unsupported_sfp=1
    '';

    # Rename ixgbe ports by PCI function suffix via ID_PATH glob.
    # The full BDF (e.g. pci-0000:44:00.0) shifts across Thunderbolt reconnects,
    # but the trailing :00.0 / :00.1 function number is stable and uniquely
    # identifies port 0 vs port 1 of the dual-port card.
    systemd.network.links = {
      "10-ixgbe0" = {
        matchConfig = {
          Driver = "ixgbe";
          Path = "*:00.0";
        };
        linkConfig.Name = "ixgbe0";
      };
      "11-ixgbe1" = {
        matchConfig = {
          Driver = "ixgbe";
          Path = "*:00.1";
        };
        linkConfig.Name = "ixgbe1";
      };
    };

    # Thunderbolt link stability for USB4-tunneled ixgbe NIC.
    #
    # Without these rules the Thunderbolt chain drops every ~60s:
    #   AMD 1022:150a PCIe USB4 Bridge (00:01.1, 00:01.2) — root of the TB tree,
    #     power/control=auto d3cold_allowed=1 by default. When it suspends it
    #     kills all downstream devices including the NIC.
    #   Intel 8086:0b26 Goshen Ridge bridges — already pinned via existing rules
    #     in goldenball/configuration.nix.
    #   Intel 8086:15ef JHL7440 bridges (inside the DM7801BJ enclosure) — already
    #     pinned via existing rules in goldenball/configuration.nix.
    #
    # 1022:150a must also be pinned to prevent the root from suspending.
    # These PCI rules must run before systemd's 80-drivers.rules on every add
    # event, including boot coldplug and docking hotplug. Otherwise udev's kmod
    # builtin can autoload ixgbe while the tunneled X520 is still in D3cold.
    # Thunderbolt authorization stays with boltd; pre-authorizing the TB chain
    # via udev can leave hotplugged docks authorized without a PCIe tunnel.
    services.udev = {
      packages = [
        (pkgs.writeTextFile {
          name = "79-usb4-sfp-pm-rules";
          destination = "/etc/udev/rules.d/79-usb4-sfp-pm.rules";
          text = ''
            # AMD Strix Halo PCIe USB4 Bridge - root of the Thunderbolt tree.
            # Must not runtime-suspend or all downstream TB devices disconnect.
            ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x1022", ATTR{device}=="0x150a", ATTR{power/control}="on"
            ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x1022", ATTR{device}=="0x150a", ATTR{d3cold_allowed}="0"

            # Intel X520/82599 SFP+ functions in the TB enclosure. If these enter
            # D3cold before ixgbe binds, probe fails with "device inaccessible".
            ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x10fb", ATTR{power/control}="on"
            ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x10fb", ATTR{d3cold_allowed}="0"
          '';
        })
      ];

      extraRules = ''
        # Trigger ethtool settings when the renamed interface appears.
        # "move" is the udev action fired when udevd renames the interface.
        ACTION=="add|move", SUBSYSTEM=="net", KERNEL=="ixgbe0", RUN+="${pkgs.systemd}/bin/systemctl restart ixgbe-force-settings.service"
      '';
    };

    # Apply ethtool settings after the interface comes up.
    # Disabling offloads and flow control reduces the intermittent freeze seen
    # on ixgbe when running over a bandwidth-limited Thunderbolt PCIe tunnel.
    systemd.services.ixgbe-force-settings = {
      description = "Apply ixgbe ethtool settings";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      path = [ pkgs.ethtool pkgs.coreutils pkgs.iproute2 ];
      script = ''
        if ip link show ixgbe0 &>/dev/null; then
          sleep 3
          echo "Applying ixgbe0 settings..."
          ethtool -A ixgbe0 autoneg off rx off tx off || true
          ethtool -K ixgbe0 gso off tso off gro off lro off || true
          ethtool -C ixgbe0 rx-usecs 0 tx-usecs 0 || true
          echo "ixgbe0 settings applied"
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
  };
}
