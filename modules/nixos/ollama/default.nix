let
  ollamaPort = 11434;
in

{ lib, config, pkgs, ... }: {

  options = {
    mine.ollama.enable =
      lib.mkEnableOption "enable ollama";
  };

  config = lib.mkIf config.mine.ollama.enable {
    services.ollama = {
      enable = true;
      package = pkgs.ollama-cuda;
      host = "0.0.0.0";
      port = ollamaPort;
      # default store: /var/lib/ollama/models
      loadModels = [
        "llama3.1:8b"
        "gemma3:12b"
        "qwen2.5-coder:14b"
        "qwen3:14b"
      ];
    };
  };
}
