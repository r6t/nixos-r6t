{ lib, config, pkgs, ... }:

let
  cfg = config.mine.nvidia-cuda;
in
{

  options.mine.nvidia-cuda = {
    enable = lib.mkEnableOption "configure nvidia gpu for cuda";

    package = lib.mkOption {
      type = lib.types.enum [ "production" "stable" "latest" ];
      default = "production";
      description = ''
        NVIDIA driver package to use.
        - production
        - stable
        - latest
      '';
    };

    containerToolkit = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable nvidia-container-toolkit for GPU passthrough to containers.
        Required for Docker/Incus containers that need GPU access.
      '';
    };

    installCudaToolkit = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Install CUDA toolkit (nvcc, headers, etc.) on the system.
        Set to true for physical hosts that compile CUDA code or run local GPU workloads.
        Set to false for containers that use nvidia-container-toolkit (runtime libraries mounted from host).
      '';
    };

    gspFirmware = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable GSP (GPU System Processor) firmware.
        Required for RTX 50 series, recommended for RTX 40 series.
      '';
    };
  };

  config = lib.mkIf cfg.enable {

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
        open = true;
        nvidiaSettings = false;
        gsp.enable = cfg.gspFirmware;
      };
      nvidia-container-toolkit.enable = cfg.containerToolkit;
    };

    nixpkgs = {
      config = {
        allowUnfree = true;
        cudaSupport = true;
        nvidia.acceptLicense = true;
      };
    };
    services.xserver.videoDrivers = [ "nvidia" ];
  };
}
