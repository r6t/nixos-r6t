{
  flake.modules.nixos.nvidia-container-host = { lib, ... }: {
    imports = [
      ../../nixos/nvidia-cuda/options.nix
      ../../nixos/nvidia-cuda/config.nix
    ];

    mine.nvidia-cuda = {
      open = lib.mkDefault true;
      containerToolkit = lib.mkDefault true;
      installCudaToolkit = lib.mkDefault false;
      gspFirmware = lib.mkDefault true;
    };
  };
}
