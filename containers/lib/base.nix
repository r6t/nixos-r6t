{ lib, pkgs, modulesPath, config, ... }:

let
  commonPackages = import ../../modules/lib/common-packages.nix pkgs;
in
{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
    ../../modules/nixos/localization/default.nix
    ./dns-overrides.nix
  ];

  boot.isContainer = true;
  system.stateVersion = "23.11";

  # Common set plus container-specific extras
  environment.systemPackages = commonPackages ++ (with pkgs; [
    awscli2
    cloud-init
    drill
    iotop
    iproute2
    mtr
    nethogs
    nettools
    traceroute
  ]);

  mine.localization.enable = true;

  # Default to LAN DNS overrides for performance, but containers
  # on the tailnet (mine.tailscale.enable = true) should prefer
  # the encrypted Tailscale path instead.
  mine.dns-overrides.enable = lib.mkDefault (!config.mine.tailscale.enable);

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
        # Primary upstream server is provided by mullvad-dns.nix, 
        # nextdns.nix, or tailscale module.
      };
    };
  };

  programs.fish.enable = true;
  users.users.root.shell = pkgs.fish;
}
