{ ... }:

{
  imports = [
    ./lib/base.nix
    ./lib/mullvad-dns.nix
    ../modules/nixos/docker/default.nix
  ];

  networking = {
    hostName = "ladder";
    firewall = {
      allowedTCPPorts = [ 8082 ];
      extraCommands = ''
        iptables -I INPUT 1 -i br-+ -p udp --dport 53 -j ACCEPT
        iptables -I INPUT 1 -i br-+ -p tcp --dport 53 -j ACCEPT
      '';
    };
  };

  mine.docker.enable = true;

  # Docker bridge networks and some containerized services expect this.
  boot.kernel.sysctl."vm.overcommit_memory" = "1";

  virtualisation.oci-containers = {
    backend = "docker";
    containers.ladder = {
      image = "ghcr.io/everywall/ladder:latest";
      pull = "always";
      environment = {
        PORT = "8082";
      };
      networks = [ "host" ];
    };
  };
}
