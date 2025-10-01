{ lib, pkgs, modulesPath, ... }:
{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
    ../modules/nixos/localization/default.nix
  ];

  boot.isContainer = true;
  system.stateVersion = "23.11";

  environment.systemPackages = with pkgs; [
    cloud-init
    curl
    dig
    dig
    drill
    ethtool
    fd
    git
    git-remote-codecommit
    gnumake
    htop
    iotop
    iproute2
    lshw
    mtr
    neovim
    netcat
    nethogs
    nettools
    nmap
    openssl
    pciutils
    ripgrep
    tcpdump
    traceroute
    tree
    unzip
    usbutils
    wget
    zip
  ];

  mine.localization.enable = true;

  networking = {
    firewall.enable = true;
    useDHCP = false;
    useNetworkd = false;
    nameservers = lib.mkDefault [ "127.0.0.1" ];
    interfaces = { };
  };

  services = {
    cloud-init = {
      enable = true;
      network.enable = true;
      settings.datasource_list = [ "NoCloud" ];
    };


    # dnsmasq gets port 53
    resolved.enable = lib.mkForce false;

    # local DNS resolver on all the LXCs!
    dnsmasq = {
      enable = true;
      resolveLocalQueries = false;
      settings = {
        no-resolv = true;
        no-poll = true;
        cache-size = 10000;
        no-negcache = true;
        dns-forward-max = 1500;
        domain-needed = true;

        # Local overrides (hairpin NAT avoidance)
        address = [
          # specific overrides
          "/headscale.r6t.io/192.168.6.9"
          "/homeassistant.r6t.io/100.64.0.8"
          "/t2.r6t.io/192.168.6.9"
          "/t6.r6t.io/192.168.6.9"
          "/t7.r6t.io/192.168.6.9"
          "/t8.r6t.io/192.168.6.9"

          # wildcard so app LXCs hit host caddy
          "/r6t.io/192.168.6.10"
        ];

        # needs 127.0.0.1#53 DNS to be provided
        server = [
          "127.0.0.1#5353"
        ];
      };
    };
  };

  programs.fish.enable = true;
  users.users.root.shell = pkgs.fish;
}

