{ lib, ... }:
{
  networking.nameservers = [ "127.0.0.1" ];
  services = {
    # dnsmasq gets port 53
    resolved.enable = lib.mkForce false;

    # extra params for nextdns reporting
    dnsmasq.settings = {
      add-mac = true;
      add-subnet = "32,128";
    };

    # 5353/udp nextdns service with mapped in config
    nextdns = {
      enable = true;
      arguments = [
        "-config-file"
        "/mnt/nextdns.conf"
      ];
    };
  };
}

