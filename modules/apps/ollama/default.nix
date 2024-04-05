{ lib, config, ... }: { 

    options = {
      mine.ollama.enable =
        lib.mkEnableOption "enable and configure ollama";
    };

    config = lib.mkIf config.mine.ollama.enable { 
      services.ollama = {
        enable = true;
        acceleration = "cuda";
      };
    };
}