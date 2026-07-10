{ inputs, ... }:

{
  flake.modules.nixos.router = { lib, ... }: {
    imports = [
      inputs.self.modules.nixos.monitoring-agent
      ../../nixos/home-router/options.nix
      ../../nixos/home-router/config.nix
    ];

    mine = {
      alloy.syslogListen = lib.mkDefault true;
      home-router = {
        cake.enable = lib.mkDefault true;
        healthCheck.enable = lib.mkDefault true;
        wanWatchdog.enable = lib.mkDefault true;
      };
    };
  };
}
