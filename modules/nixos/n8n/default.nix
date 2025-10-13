let
  n8nPort = 5678; # standard n8n default port
in

{ lib, config, ... }: {

  options = {
    mine.n8n.enable =
      lib.mkEnableOption "enable n8n";
  };

  config = lib.mkIf config.mine.n8n.enable {
    services.n8n = {
      enable = true;
      webhookUrl = "https://n8n.r6t.io";
      settings = {
        listen_address = "0.0.0.0";
        port = n8nPort;
      };
    };
  };
}
