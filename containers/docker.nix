{
  imports = [
    ./r6-lxc-base.nix
    ./r6-lxc-mullvad-dns-add-on.nix
    ../modules/nixos/docker/default.nix
  ];

  # append DNS server settings: crown DNS override
  # allows workloads not on tailnet to use same DNS names
  services = {
    dnsmasq = {
      settings = {
        address = [
          # specific overrides
          "/grafana.r6t.io/192.168.6.1"

          # wildcard so app LXCs hit router caddy
          "/r6t.io/192.168.6.10"
        ];
      };
    };
  };

  mine.docker.enable = true;

  # at least redis wants this
  boot.kernel.sysctl."vm.overcommit_memory" = "1";
}

