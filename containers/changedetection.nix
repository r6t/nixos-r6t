{
  imports = [
    ./r6-lxc-base.nix
    ./r6-lxc-mullvad-dns-add-on.nix
  ];

  networking.hostName = "changedetection";

  services = {
    dnsmasq = {
      settings = {
        address = [
          "/grafana.r6t.io/192.168.6.1"
          "/r6t.io/192.168.6.10"
        ];
      };
    };

    changedetection-io = {
      enable = true;
      behindProxy = true;
      baseURL = "https://changed.r6t.io";
      listenAddress = "0.0.0.0";
      port = 5000;
      datastorePath = "/var/lib/changedetection-io";
      playwrightSupport = true;
    };
  };

  networking.firewall.allowedTCPPorts = [ 5000 ];
}
