{ lib, config, pkgs, ... }: {

  options = {
    mine.nvidia-cuda.enable =
      lib.mkEnableOption "configure nvidia gpu for cuda";
  };

  config = lib.mkIf config.mine.nvidia-cuda.enable {

    nixpkgs.config.nvidia.acceptLicense = true;
    nixpkgs.config.cudaSupport = true;
    environment.systemPackages = with pkgs; [ cudatoolkit libva ];
    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
      };
      nvidia = {
        package = config.boot.kernelPackages.nvidiaPackages.stable;
        modesetting.enable = false;
        powerManagement.enable = true;
        open = false;
        nvidiaSettings = false;
      };
      nvidia-container-toolkit.enable = true;
    };
    services.xserver.videoDrivers = [ "nvidia" ];
  };
}

