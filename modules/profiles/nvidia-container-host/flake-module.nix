{
  flake.modules.nixos.nvidia-container-host = { lib, ... }: {
    mine.nvidia-cuda = {
      enable = lib.mkDefault true;
      open = lib.mkDefault true;
      containerToolkit = lib.mkDefault true;
      installCudaToolkit = lib.mkDefault false;
      gspFirmware = lib.mkDefault true;
    };
  };
}
