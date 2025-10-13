let
  open-webuiPort = 8087;
in

{ lib, config, ... }: {

  options = {
    mine.open-webui.enable =
      lib.mkEnableOption "enable open-webui";
  };

  config = lib.mkIf config.mine.open-webui.enable {
    services.open-webui = {
      enable = true;
      host = "0.0.0.0";
      port = open-webuiPort;
      stateDir = "/var/lib/open-webui"; # open-webui nixpkgs default
      environment = {
        ANONYMIZED_TELEMETRY = "False";
        DO_NOT_TRACK = "True";
        SCARF_NO_ANALYTICS = "True";
        OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
        WEBUI_AUTH = "False"; # disable authentication
      };
    };
  };
}
