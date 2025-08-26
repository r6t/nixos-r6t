{ pkgs, lib, ... }:
{
  imports = [
    ./r6-lxc-base.nix
    ../modules/nixos/caddy/default.nix
  ];

  networking = {
    hostName = "headscale";
    firewall = {
      enable = true;
      allowedTCPPorts = [ 443 ];
    };
  };

  services = {
    headscale = {
      enable = true;
      # port = 8080; # default
      # address = "127.0.0.1" # caddy listens on 0/0 and proxies in
      settings = {
        server_url = "https://headscale.r6t.io";
        dns.base_domain = "r6.internal";
        dns.nameservers.global = [ "192.168.6.1" ];
      };
    };
  };

  mine.caddy.enable = true;
}

