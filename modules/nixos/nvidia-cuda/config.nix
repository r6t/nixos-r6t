{ lib, config, pkgs, ... }:

let
  cfg = config.mine.nvidia-cuda;
in
{
  environment.systemPackages =
    lib.optionals cfg.installCudaToolkit (with pkgs; [
      # Install cudatoolkit for physical hosts that need nvcc, CUDA headers, etc.
      # Containers don't need this - nvidia-container-toolkit mounts runtime libs from host
      cudatoolkit
    ]);

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    nvidia = {
      package =
        if cfg.package == "latest" then
          config.boot.kernelPackages.nvidiaPackages.latest
        else if cfg.package == "stable" then
          config.boot.kernelPackages.nvidiaPackages.stable
        else
          config.boot.kernelPackages.nvidiaPackages.production;
      modesetting.enable = true;
      powerManagement.enable = false;
      inherit (cfg) open;
      nvidiaSettings = false;
      gsp.enable = cfg.gspFirmware;
      prime.allowExternalGpu = cfg.allowExternalGpu;
    };
    nvidia-container-toolkit.enable = cfg.containerToolkit;
  };

  nixpkgs.config = {
    allowUnfree = true;
    cudaSupport = true;
    nvidia.acceptLicense = true;
  };
  services.xserver.videoDrivers = [ "nvidia" ];
}
