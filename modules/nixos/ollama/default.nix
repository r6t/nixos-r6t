{ lib, config, inputs, ... }:let
  # ad-hoc import nixpkgs-unstable to set config. I'd rather avoid the extra import but was having trouble getting it to work otherwise
  nixpkgs-unstable = import inputs.nixpkgs-unstable {
    system = "x86_64-linux";
    config = { allowUnfree = true; };
  };
  ollamaPackage = nixpkgs-unstable.ollama;
in { 
    options = {
      mine.ollama.enable =
        lib.mkEnableOption "enable ollama server (nvidia)";
    };
    config = lib.mkIf config.mine.ollama.enable { 
      services.ollama = {
        enable = true;
        acceleration = "cuda";
        package = ollamaPackage;
        # host = "0.0.0.0"; # use older listenAddress on 24.05
        # port = 11434;
        listenAddress = "0.0.0.0:11434";
      };
    };
}
