{ lib, config, pkgs, ... }: {

  options = {
    mine.ollama.enable =
      lib.mkEnableOption "enable ollama with models loaded";
  };

  config = lib.mkIf config.mine.ollama.enable {
    services.ollama = {
      enable = true;
      package = pkgs.ollama;
      # TODO causing errors 2025-03-29
      #      loadModels = [
      #        "deepseek-r1:14b"
      #        "gemma3:12b"
      #      ];
    };
  };
}
