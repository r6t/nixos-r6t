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
      default = "";
      description = ''
        Ollama API base URL. Set to "" to disable Ollama backend.
      '';
    };

    openaiApiUrl = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        OpenAI-compatible API base URL (e.g. http://localhost:8080/v1).
        Used for llama-server, vLLM, or any OpenAI-compatible backend.
        Set to "" to disable.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.open-webui = {
      enable = true;
      inherit (cfg) host port;
      stateDir = "/var/lib/open-webui"; # open-webui nixpkgs default
      environment =
        {
          ANONYMIZED_TELEMETRY = "False";
          DO_NOT_TRACK = "True";
          SCARF_NO_ANALYTICS = "True";
          WEBUI_AUTH = "False"; # disable authentication
        }
        // lib.optionalAttrs (cfg.ollamaUrl != "") {
          OLLAMA_API_BASE_URL = cfg.ollamaUrl;
        }
        // lib.optionalAttrs (cfg.openaiApiUrl != "") {
          OPENAI_API_BASE_URLS = cfg.openaiApiUrl;
          OPENAI_API_KEYS = "dummy"; # required by open-webui but unused for local APIs
        };
    };
  };
}
