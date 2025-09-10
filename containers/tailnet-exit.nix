{
  imports = [
    ./r6-lxc-base.nix
    ./r6-lxc-mullvad-dns-add-on.nix
    ../modules/nixos/exit-node-routing/default.nix
  ];

  mine.exit-node-routing.enable = true;

}

