{
  imports = [
    ./r6-lxc-base.nix
    ./r6-lxc-mullvad-dns-add-on.nix
    ../modules/nixos/docker/default.nix
  ];

  networking = {
    hostName = "docker-lxc";
  };

  mine.docker.enable = true;

  # at least redis wants this
  boot.kernel.sysctl."vm.overcommit_memory" = "1";

}

