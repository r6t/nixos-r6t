{ lib, config, ... }:
let
  cfg = config.mine.open-webui;
in
{

  options.mine.open-webui = {
    enable =
      lib.mkEnableOption "enable open-webui";

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address for open-webui to listen on.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8087;
      description = "Port for open-webui to listen on.";
    };

    ollamaUrl = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:11434";
      description = "Ollama API base URL.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.open-webui = {
      enable = true;
      host = cfg.host;
      port = cfg.port;
      stateDir = "/var/lib/open-webui"; # open-webui nixpkgs default
      environment = {
        ANONYMIZED_TELEMETRY = "False";
        DO_NOT_TRACK = "True";
        SCARF_NO_ANALYTICS = "True";
        OLLAMA_API_BASE_URL = cfg.ollamaUrl;
        WEBUI_AUTH = "False"; # disable authentication
      };
    };
  };
}
