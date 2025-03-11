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
        modesetting.enable = true;
        powerManagement.enable = true; # changed from default false
        open = false;
        nvidiaSettings = true;
      };
      nvidia-container-toolkit.enable = true;
    };
  };
}

