{
  flake.modules.nixos.router = { lib, ... }: {
    mine = {
      alloy.syslogListen = lib.mkDefault true;
      home-router = {
        enable = lib.mkDefault true;
        cake.enable = lib.mkDefault true;
        healthCheck.enable = lib.mkDefault true;
        wanWatchdog.enable = lib.mkDefault true;
      };
    };
  };
}
