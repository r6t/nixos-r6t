{ lib, config, pkgs, ... }: {

  options = {
    mine.ollama.enable =
      lib.mkEnableOption "enable ollama + webui for nvidia/cuda with models loaded";
  };

  config = lib.mkIf config.mine.ollama.enable {
    services.ollama = {
      enable = true;
      host = "0.0.0.0"; # default port tcp/11434
      package = pkgs.ollama-cuda;
      acceleration = "cuda";
      # TODO causing errors 2025-03-29
      loadModels = [
        "deepseek-r1:14b"
        "deepseek-r1:8b"
        "gemma3:12b"
      ];
    };
    services.open-webui = {
      enable = true;
      host = "0.0.0.0"; # default port tcp/8080
      # stateDir = "/var/lib/open-webui"; # default value
    };
  };
}
