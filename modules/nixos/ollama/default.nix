{ lib, config, ... }: { 

    options = {
      mine.ollama.enable =
        lib.mkEnableOption "enable ollama server (nvidia)";
    };

    config = lib.mkIf config.mine.ollama.enable { 
      services.ollama = {
        enable = true;
        acceleration = "cuda";
	host = "0.0.0.0";
        port = 11434;
        # listenAddress = "0.0.0.0:11434"; replaced by above two
      };
    };
}
