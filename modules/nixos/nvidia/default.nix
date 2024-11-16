{ lib, config, pkgs, ... }: { 

    options = {
      mine.nvidia.enable =
        lib.mkEnableOption "configure nvidia gpu";
    };

    config = lib.mkIf config.mine.nvidia.enable { 
      
      boot.kernelParams = [ 
        "nvidia-drm.modeset=1" # troubleshooting gpu fan bottoming out at 30
        "nvidia.NVreg_PreserveVideoMemoryAllocations=1"  # sleep/wake
        ];

      environment.systemPackages = with pkgs; [ libva ];

      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      };

      hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = true; # changed from default false
        open = false;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
          version = "555.58.02";
          sha256_64bit = "sha256-xctt4TPRlOJ6r5S54h5W6PT6/3Zy2R4ASNFPu8TSHKM=";
          sha256_aarch64 = "sha256-xctt4TPRlOJ6r5S54h5W6PT6/3Zy2R4ASNFPu8TSHKM=";
          openSha256 = "sha256-ZpuVZybW6CFN/gz9rx+UJvQ715FZnAOYfHn5jt5Z2C8=";
          settingsSha256 = "sha256-ZpuVZybW6CFN/gz9rx+UJvQ715FZnAOYfHn5jt5Z2C8=";
          persistencedSha256 = lib.fakeSha256;
        };
      #package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      #    version = "555.42.02";
      #    sha256_64bit = "sha256-k7cI3ZDlKp4mT46jMkLaIrc2YUx1lh1wj/J4SVSHWyk=";
      #    sha256_aarch64 = lib.fakeSha256;
      #    openSha256 = "sha256-rtDxQjClJ+gyrCLvdZlT56YyHQ4sbaL+d5tL4L4VfkA=";
      #    settingsSha256 = "sha256-rtDxQjClJ+gyrCLvdZlT56YyHQ4sbaL+d5tL4L4VfkA=";
      #    persistencedSha256 = lib.fakeSha256;
      #  };
      };

      hardware.nvidia-container-toolkit.enable = true;

      services.xserver = {
        videoDrivers = ["nvidia"];
      };
    };
}
