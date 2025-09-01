{
  imports = [
    ./r6-lxc-base.nix
    ./r6-lxc-nextdns-add-on.nix
  ];

  networking = {
    hostName = "dns";
    firewall = {
      enable = true;
      allowedTCPPorts = [ 53 ];
      allowedUDPPorts = [ 53 ];
    };
    # this LXC establishes internal LAN DNS - nameservers for initial DoH connection
    nameservers = [ "9.9.9.9" "84.200.69.80" ];
  };

}

