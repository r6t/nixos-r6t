_:
{
  # nameservers and resolved already handled by base.nix
  services = {
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

    # Forward all other queries to local NextDNS-CLI
    dnsmasq.settings.server = [ "127.0.0.1#5353" ];
  };
}

