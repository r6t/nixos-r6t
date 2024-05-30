{ lib, config, ... }: { 

    options = {
      mine.ollama.enable =
        lib.mkEnableOption "enable ollama server (nvidia)";
    };

    config = lib.mkIf config.mine.ollama.enable { 
      services.ollama = {
        enable = true;
        acceleration = "cuda";
        # listenAddress = "0.0.0.0:11434";
        port = 11434;
      };
    };
}