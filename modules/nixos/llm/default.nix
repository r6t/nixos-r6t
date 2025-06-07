let
  ollamaPort = 11434;
  ollamaFqdn = "ollama.r6t.io";
  webuiPort = 8080;

in

{ lib, config, pkgs, ... }: {

  options = {
    mine.llm.enable =
      lib.mkEnableOption "enable LLM services: ollama, open-webui";
  };

  config = lib.mkIf config.mine.llm.enable {
    services.ollama = {
      enable = true;
      package = pkgs.ollama-cuda;
      acceleration = "cuda";
      host = "0.0.0.0";
      port = ollamaPort;
      environmentVariables = {
        OLLAMA_ORIGINS = "http://localhost:${toString webuiPort},http://127.0.0.1:${toString webuiPort},https://${ollamaFqdn}";
      };
      loadModels = [ "llama3:8b" ];
    };

    #    services.open-webui = {
    #      enable = true;
    #      port = webuiPort;
    #      environment = {
    #        OLLAMA_BASE_URL = "http://localhost:${toString ollamaPort}";
    #        OLLAMA_API_BASE_URL = "http://localhost:${toString ollamaPort}/api";
    #        WEBUI_SECRET_KEY = "";
    #        SCARF_NO_ANALYTICS = "true";
    #        DO_NOT_TRACK = "true";
    #        ANONYMIZED_TELEMETRY = "false";
    #      };
    #    };
  };
}
