{
  flake.modules.nixos.nvidia-cuda-workload = { lib, ... }: {
    mine.nvidia-cuda = {
      enable = lib.mkDefault true;
      open = lib.mkDefault true;
      package = lib.mkDefault "latest";
      containerToolkit = lib.mkDefault false;
      installCudaToolkit = lib.mkDefault true;
    };
  };
}
