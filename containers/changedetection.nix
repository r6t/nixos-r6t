{
  imports = [
    ./lib/base.nix
    ./lib/mullvad-dns.nix
  ];

  networking.hostName = "changedetection";

  services = {
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
