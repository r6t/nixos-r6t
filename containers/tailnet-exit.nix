{
  imports = [
    ./lib/wg-exit-node.nix
  ];

  mine.exit-node-routing = {
    enable = true;
    enableTailscale = true;
  };
}
