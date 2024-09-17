{ lib, config, inputs, ... }: { 

    options = {
      mine.ollama.enable =
        lib.mkEnableOption "enable ollama server (nvidia)";
    };

    config = lib.mkIf config.mine.ollama.enable { 
      services.ollama = {
        enable = true;
        acceleration = "cuda";
        package = inputs.nixpkgs-unstable.legacyPackages.x86_64-linux.ollama;
        # host = "0.0.0.0"; # use older listenAddress on 24.05
        listenAddress = "0.0.0.0:11434";
        # port = 11434;
      };
    };
}
