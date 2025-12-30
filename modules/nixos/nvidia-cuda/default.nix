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
        - production: Latest production driver (supports RTX 20 series and newer)
        - stable: Stable driver branch
        - latest: Beta/latest driver (for RTX 50-series and newer)
      '';
    };

    openDriver = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Use the open-source NVIDIA kernel modules.
        Supported on Turing (RTX 20 series) and newer.
        REQUIRED for Blackwell (RTX 50-series) - proprietary modules do NOT support Blackwell.
        Set to false only for Maxwell, Pascal, Volta GPUs (which require proprietary).
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

    prime = {
      enable = lib.mkEnableOption "NVIDIA PRIME support for hybrid graphics laptops";

      offload = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Enable PRIME offload mode for on-demand GPU switching.
          When enabled, use nvidia-offload command to run apps on dGPU.
        '';
      };

      amdgpuBusId = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "PCI:6:0:0";
        description = ''
          PCI Bus ID of the AMD integrated GPU.
          Find with: lspci | grep -E "VGA|3D"
          Format: PCI:bus:device:function (remove leading zeros, e.g., 06:00.0 -> 6:0:0)
        '';
      };

      nvidiaBusId = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "PCI:1:0:0";
        description = ''
          PCI Bus ID of the NVIDIA discrete GPU.
          Find with: lspci | grep -E "VGA|3D"
          Format: PCI:bus:device:function (remove leading zeros)
        '';
      };
    };

    powerManagement = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable NVIDIA power management features.
        Recommended for laptops to support suspend/hibernate.
        Set to true to enable hibernation support with nvidia.NVreg_PreserveVideoMemoryAllocations=1.
      '';
    };

    enableSettings = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable nvidia-settings GUI application.
        Useful for laptops and desktops with displays.
        Disable for headless servers.
      '';
    };

    enableGspFirmware = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable GPU System Processor (GSP) firmware.
        Required for RTX 50-series (Blackwell) and newer.
        Improves performance and stability on supported GPUs.
      '';
    };
  };

  config = lib.mkIf cfg.enable {

    # Add nvidia to video drivers
    services.xserver.videoDrivers = [ "nvidia" ];

    # Load NVIDIA kernel modules
    boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];

    # Add kernel parameters for NVIDIA
    boot.kernelParams =
      [ "nvidia-drm.modeset=1" ]
      ++ lib.optionals cfg.powerManagement [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ]
      ++ lib.optionals cfg.enableGspFirmware [ "nvidia.NVreg_EnableGpuFirmware=1" ];

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
        extraPackages = with pkgs; [
          nvidia-vaapi-driver
          libvdpau-va-gl
        ];
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
        powerManagement.enable = cfg.powerManagement;
        powerManagement.finegrained = false;
        open = cfg.openDriver;
        nvidiaSettings = cfg.enableSettings;

        prime = lib.mkIf cfg.prime.enable {
          offload = lib.mkIf cfg.prime.offload {
            enable = true;
            enableOffloadCmd = true;
          };
          amdgpuBusId = lib.mkIf (cfg.prime.amdgpuBusId != null) cfg.prime.amdgpuBusId;
          nvidiaBusId = lib.mkIf (cfg.prime.nvidiaBusId != null) cfg.prime.nvidiaBusId;
        };
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
  };
}

