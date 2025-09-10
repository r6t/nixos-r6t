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
      acceleration = "cuda";
      host = "0.0.0.0";
      port = ollamaPort;
      loadModels = [ "llama3:8b" ];
    };
  };
}
