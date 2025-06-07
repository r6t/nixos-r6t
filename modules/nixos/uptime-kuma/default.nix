{ lib, config, ... }:

{
  options = {
    mine.uptime-kuma.enable = lib.mkEnableOption "enable and configure uptime-kuma";
  };

  config = lib.mkIf config.mine.uptime-kuma.enable {
    services.uptime-kuma = {
      enable = true;
      settings = {
        port = "3001";
        dataDir = "/mnt/moonstore/uptime-kuma";
      };
    };
  };
}
