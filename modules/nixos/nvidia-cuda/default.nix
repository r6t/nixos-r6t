{ lib, config, pkgs, ... }:

let
  cfg = config.mine.nvidia-cuda;
in
{

  options.mine.nvidia-cuda = {
    enable = lib.mkEnableOption "configure nvidia gpu for cuda";

    package = lib.mkOption {
      type = lib.types.enum [ "production" "stable" "latest" "legacy_470" ];
      default = "production";
      description = ''
        NVIDIA driver package to use.
        - production: Latest production driver (supports GTX 16/RTX 20 series and newer)
        - stable: Stable driver branch
        - latest: Beta/latest driver
        - legacy_470: Legacy 470.xx driver (supports GTX 10 series)
      '';
    };

    openDriver = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Use the open-source NVIDIA kernel modules.
        Set to false for older GPUs (GTX 10 series and earlier).
      '';
    };

    containerToolkit = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Enable nvidia-container-toolkit for GPU passthrough to containers.
        Required for Docker/Incus containers that need GPU access.
        May have limited support with legacy drivers.
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
  };

  config = lib.mkIf cfg.enable {

    environment.systemPackages = with pkgs; [
      libva
    ] ++ lib.optionals cfg.installCudaToolkit [
      # Install cudatoolkit for physical hosts that need nvcc, CUDA headers, etc.
      # Containers don't need this - nvidia-container-toolkit mounts runtime libs from host
      cudatoolkit
    ];
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
      };
      nvidia = {
        package =
          if cfg.package == "legacy_470" then
            config.boot.kernelPackages.nvidiaPackages.legacy_470
          else if cfg.package == "latest" then
            config.boot.kernelPackages.nvidiaPackages.latest
          else if cfg.package == "stable" then
            config.boot.kernelPackages.nvidiaPackages.stable
          else
            config.boot.kernelPackages.nvidiaPackages.production;
        modesetting.enable = true;
        powerManagement.enable = false;
        open = cfg.openDriver;
        nvidiaSettings = false;
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

