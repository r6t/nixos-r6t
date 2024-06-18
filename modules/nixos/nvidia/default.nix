{ lib, config, pkgs, ... }: { 

    options = {
      mine.nvidia.enable =
        lib.mkEnableOption "configure nvidia gpu";
    };

    config = lib.mkIf config.mine.nvidia.enable { 
      
      boot.kernelParams = [ 
        "nvidia-drm.modeset=1" # troubleshooting gpu fan bottoming out at 30
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
        powerManagement.finegrained = false; # trying during troubleshooting Plasma 6 resume/wake black screen
        open = false;
        nvidiaSettings = true;
        # package = config.boot.kernelPackages.nvidiaPackages.stable;
        # package = config.boot.kernelPackages.nvidiaPackages.beta; it's still 550
        ###
        package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
          #version = "535.154.05";
          #sha256_64bit = "sha256-fpUGXKprgt6SYRDxSCemGXLrEsIA6GOinp+0eGbqqJg=";
          #sha256_aarch64 = "sha256-G0/GiObf/BZMkzzET8HQjdIcvCSqB1uhsinro2HLK9k=";
          #openSha256 = "sha256-wvRdHguGLxS0mR06P5Qi++pDJBCF8pJ8hr4T8O6TJIo=";
          #settingsSha256 = "sha256-9wqoDEWY4I7weWW05F4igj1Gj9wjHsREFMztfEmqm10=";
          #persistencedSha256 = "sha256-d0Q3Lk80JqkS1B54Mahu2yY/WocOqFFbZVBh+ToGhaE=";

          #version = "550.40.07";
          #sha256_64bit = "sha256-KYk2xye37v7ZW7h+uNJM/u8fNf7KyGTZjiaU03dJpK0=";
          #sha256_aarch64 = "sha256-AV7KgRXYaQGBFl7zuRcfnTGr8rS5n13nGUIe3mJTXb4=";
          #openSha256 = "sha256-mRUTEWVsbjq+psVe+kAT6MjyZuLkG2yRDxCMvDJRL1I=";
          #settingsSha256 = "sha256-c30AQa4g4a1EHmaEu1yc05oqY01y+IusbBuq+P6rMCs=";
          #persistencedSha256 = "sha256-11tLSY8uUIl4X/roNnxf5yS2PQvHvoNjnd2CB67e870=";
          # This was needed for 535 and 550
          #patches = [ rcu_patch ];

          version = "555.42.02";
          sha256_64bit = "sha256-k7cI3ZDlKp4mT46jMkLaIrc2YUx1lh1wj/J4SVSHWyk=";
          sha256_aarch64 = lib.fakeSha256;
          openSha256 = "sha256-rtDxQjClJ+gyrCLvdZlT56YyHQ4sbaL+d5tL4L4VfkA=";
          settingsSha256 = "sha256-rtDxQjClJ+gyrCLvdZlT56YyHQ4sbaL+d5tL4L4VfkA=";
          persistencedSha256 = lib.fakeSha256;
        };
        ###
      };

      programs.gamemode.enable = true;

      services.xserver = {
        videoDrivers = ["nvidia"];
      };
    };
}