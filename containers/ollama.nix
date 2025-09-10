{
  imports = [
    ../modules/nixos/nvidia-cuda/default.nix
    ../modules/nixos/ollama/default.nix
    ./docker.nix
    ./r6-lxc-base.nix
    ./r6-lxc-mullvad-dns-add-on.nix
  ];

  networking.hostName = "llm";

  mine = {
    nvidia-cuda.enable = true;
    ollama.enable = true;
  };
}

