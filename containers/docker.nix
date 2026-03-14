{
  imports = [
    ./lib/base.nix
    ./lib/mullvad-dns.nix
    ../modules/nixos/docker/default.nix
  ];

  mine.docker.enable = true;

  # at least redis wants this
  boot.kernel.sysctl."vm.overcommit_memory" = "1";
}

