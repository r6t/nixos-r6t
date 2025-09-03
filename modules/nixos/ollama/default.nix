{ lib, config, pkgs, ... }: {
  options.mine.ollama.enable =
    lib.mkEnableOption "enable ollama for nvidia/cuda with models loaded";

  config = lib.mkIf config.mine.ollama.enable {
    services.ollama = {
      enable = true;
      host = "0.0.0.0";
      package = pkgs.ollama-cuda;
      acceleration = "cuda";
      loadModels = [
        "deepseek-r1:14b"
        "deepseek-r1:8b"
        "qwen2.5-coder:14b"
        "qwen2.5-coder:7b"
        "gemma3:12b"
      ];
    };
  };
}
