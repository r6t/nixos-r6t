{ lib, config, pkgs, ... }: { 

    options = {
      mine.nvidia.enable =
        lib.mkEnableOption "configure nvidia gpu";
    };

    config = lib.mkIf config.mine.nvidia.enable { 
      
      boot.kernelParams = [ 
        "nvidia-drm.fbdev=1"  # troubleshooting plasma 6 black screen
        "nvidia.NVreg_PreserveVideoMemoryAllocations=1"  # sleep/wake
        ];

      environment.sessionVariables = {
        # GBM_BACKEND = "nvidia-drm";
        # LIBVA_DRIVER_NAME = "nvidia";
        # WLR_NO_HARDWARE_CURSORS = "1";
        # XDG_SESSION_TYPE = "wayland";
        # __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      };
      environment.systemPackages = with pkgs; [ libva ];

      hardware.opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true;
      };

      hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = true; # changed from default false
        # powerManagement.finegrained = false;
        open = false;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
      };

      services.xserver = {
        videoDrivers = ["nvidia"];
      };
    };
}