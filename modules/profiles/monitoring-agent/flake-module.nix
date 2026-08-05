{
  flake.modules.nixos.monitoring-agent = {
    imports = [
      ../../nixos/alloy/options.nix
      ../../nixos/alloy/config.nix
      ../../nixos/prometheus-node-exporter/options.nix
      ../../nixos/prometheus-node-exporter/config.nix
    ];
  };
}
