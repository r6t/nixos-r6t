{
  imports = [
    ./lib/base.nix
    ./lib/mullvad-dns.nix
    ../modules/nixos/docker/default.nix
  ];

  mine.docker.enable = true;

  # at least redis wants this
  boot.kernel.sysctl."vm.overcommit_memory" = "1";

  networking.firewall.extraRules = ''
    iptables -I INPUT 1 -i br-+ -p udp --dport 53 -j ACCEPT
    iptables -I INPUT 1 -i br-+ -p tcp --dport 53 -j ACCEPT
  '';
}

