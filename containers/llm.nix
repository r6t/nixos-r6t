{ config, pkgs, lib, ... }:
{
  imports = [
    ./r6-lxc-base.nix
    ../modules/nixos/nvidia-cuda/default.nix
    ../modules/nixos/ollama/default.nix
  ];

  networking.hostName = "llm";

  mine = {
    nvidia-cuda.enable = true;
    ollama.enable = true;
  };

  nixpkgs.overlays = [
    (final: prev: {
      python3Packages = prev.python3Packages.overrideScope (pyfinal: pyprev: {
        einops = pyprev.einops.overridePythonAttrs (old: {
          checkPhase = ''
            echo "Skipping einops tests due to persistent image build failures."
          '';
        });

        chromadb = pyprev.chromadb.overridePythonAttrs (oldAttrs: {
          checkPhase = ''
            echo "Skipping chromadb tests due to pytest-xdist parallel error."
          '';
        });
      });
    })
  ];
}
