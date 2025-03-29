{ lib, config, pkgs, ... }: {

  options = {
    mine.ollama-cuda.enable =
      lib.mkEnableOption "enable ollama-cuda with models loaded";
  };

  config = lib.mkIf config.mine.ollama-cuda.enable {
    services.ollama = {
      enable = true;
      package = pkgs.ollama-cuda;
      # TODO causing errors 2025-03-29
      #      loadModels = [
      #        "deepseek-r1:14b"
      #        "gemma3:12b"
      #      ];
    };
  };
}
