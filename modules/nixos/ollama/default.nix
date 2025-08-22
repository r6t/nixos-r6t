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
      loadModels = [
        "deepseek-r1:14b"
        "deepseek-r1:8b"
        "qwen2.5-coder:14b"
        "qwen2.5-coder:8b"
        "gemma3:12b"
      ];
    };
    services.open-webui = {
      enable = true;
      environmentFile = "/var/lib/oi.env";
      host = "0.0.0.0"; # default port tcp/8080
    };
  };
}
