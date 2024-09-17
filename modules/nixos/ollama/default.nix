{ lib, config, inputs, ... }:let
  # Perform an ad-hoc import for `nixpkgs-unstable` with the desired configuration.
  nixpkgs-unstable = import inputs.nixpkgs-unstable {
    system = "x86_64-linux";
    config = { allowUnfree = true; };
  };

  # Define the package using the ad-hoc imported and configured `nixpkgs-unstable`
  ollamaPackage = nixpkgs-unstable.legacyPackages.x86_64-linux.ollama;
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
        # package = inputs.nixpkgs-unstable.legacyPackages.x86_64-linux.ollama;
        # host = "0.0.0.0"; # use older listenAddress on 24.05
        listenAddress = "0.0.0.0:11434";
        # port = 11434;
      };
    };
}
