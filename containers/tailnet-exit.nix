{ pkgs, lib, ... }:
{
  imports = [
    ./r6-lxc-base.nix
  ];

  networking = {
    hostName = "exit-node-lxc";
    firewall.checkReversePath = "loose";
  };

  services = {
    networkd-dispatcher = {
      enable = true;
      rules."50-tailscale" = {
        onState = [ "routable" ];
        # GRO forwarding for exit node
        # https://tailscale.com/kb/1320/performance-best-practices#ethtool-configuration
        script = ''
          ${lib.getExe pkgs.ethtool} -K eth0 rx-udp-gro-forwarding on rx-gro-list off
        '';
      };
    };
    tailscale = {
      enable = true;
      useRoutingFeatures = "server";
    };
  };

  systemd.services.tailscaled = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
  };
}

