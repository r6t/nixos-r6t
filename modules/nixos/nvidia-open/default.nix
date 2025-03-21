{ lib, config, pkgs, ... }: {

  options = {
    mine.nvidia-open.enable =
      lib.mkEnableOption "configure nvidia-open for general desktop use";
  };

  config = lib.mkIf config.mine.nvidia-open.enable {

    boot.kernelParams = [
      "nvidia-drm.fbdev=1"
      "nvidia-drm.modeset=1"
      "nouveau.modeset=0"
      "rd.driver.blacklist=nouveau"
      "modprobe.blacklist=nouveau"
      #    "nvidia.NVreg_InitializeSystemMemoryAllocations=0"
      #    "nvidia.NVreg_UsePageAttributeTable=1"
      #    "nvidia.NVreg_EnableGpuFirmware=0"
      #    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    ];

    environment.systemPackages = with pkgs; [ libva ];
    environment.sessionVariables = {
      WLR_NO_HARDWARE_CURSORS = "1";
      NIXOS_OZONE_WL = "1";
      VK_ICD_FILENAMES = "/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    };

    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
      };
      nvidia = {
        forceFullCompositionPipeline = true;
        modesetting.enable = true;
        open = true;
        package = config.boot.kernelPackages.nvidiaPackages.production; # or latest, stable
        nvidiaSettings = true;
        #        powerManagement = {
        #          enable = true;
        #	  # finegraned = false;
        #	};
      };
    };

    nixpkgs.config.nvidia.acceptLicense = true;
    services.xserver.videoDrivers = [ "nvidia" ];
  };
}
