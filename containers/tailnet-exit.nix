{ config, pkgs, lib, userConfig, ... }:
{
  imports = [
    ./r6-lxc-base.nix
  ];

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "server";
  };

  # maybe useRoutingFeatures=server does everything?
  # boot.kernel.sysctl = {
  #   "net.ipv4.ip_forward" = 1;
  #   "net.ipv6.conf.all.forwarding" = 1;
  #   "net.ipv6.conf.default.forwarding" = 1;
  # };

  networking = {
    hostName = "exit-node-lxc";
    firewall = {
      trustedInterfaces = [ "tailscale0" ];
    };
  };
}
