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
        # Used these with hyprland, now using plasma 6
        # GBM_BACKEND = "nvidia-drm";
        # LIBVA_DRIVER_NAME = "nvidia";
        # WLR_NO_HARDWARE_CURSORS = "1";
        # XDG_SESSION_TYPE = "wayland";
        # __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      };
      environment.systemPackages = with pkgs; [ libva ];

      # replaces hardware.opengl after nixos 24.05
      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      # the old way
      # hardware.opengl = {
      #   enable = true;
      #   driSupport = true;
      #   driSupport32Bit = true;
      # };
      
      hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = true; # changed from default false
        open = false;
        nvidiaSettings = true;
        # package = config.boot.kernelPackages.nvidiaPackages.stable;
        package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
          version = "555.42.02";
          sha256_64bit = "sha256-k7cI3ZDlKp4mT46jMkLaIrc2YUx1lh1wj/J4SVSHWyk=";
          sha256_aarch64 = lib.fakeSha256;
          openSha256 = "sha256-rtDxQjClJ+gyrCLvdZlT56YyHQ4sbaL+d5tL4L4VfkA=";
          settingsSha256 = "sha256-rtDxQjClJ+gyrCLvdZlT56YyHQ4sbaL+d5tL4L4VfkA=";
          persistencedSha256 = lib.fakeSha256;
        };
      };

      hardware.nvidia-container-toolkit.enable = true;

      programs.gamemode.enable = true;

      services.xserver = {
        videoDrivers = ["nvidia"];
      };
    };
}
