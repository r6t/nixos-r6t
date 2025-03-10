{ lib, config, pkgs, ... }: {

  options = {
    mine.nvidia.enable =
      lib.mkEnableOption "configure nvidia gpu";
  };

  config = lib.mkIf config.mine.nvidia.enable {

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

