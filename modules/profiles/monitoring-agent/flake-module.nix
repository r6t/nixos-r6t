{
  flake.modules.nixos.monitoring-agent = {
    imports = [
      ../../nixos/alloy/config.nix
      ../../nixos/prometheus-node-exporter/config.nix
    ];
  };
}
