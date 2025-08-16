{ lib, config, pkgs, ... }: {

  options = {
    mine.nvidia-cuda.enable =
      lib.mkEnableOption "configure nvidia gpu for cuda";
  };

  config = lib.mkIf config.mine.nvidia-cuda.enable {

    environment.systemPackages = with pkgs; [ cudatoolkit libva ];
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
      };
      nvidia = {
        package = config.boot.kernelPackages.nvidiaPackages.production; # or latest, stable
        modesetting.enable = true;
        powerManagement.enable = false;
        open = true;
        nvidiaSettings = false;
      };
      nvidia-container-toolkit.enable = true;
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

