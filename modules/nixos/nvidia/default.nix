{ lib, config, pkgs, ... }: { 

    options = {
      mine.nvidia.enable =
        lib.mkEnableOption "configure nvidia gpu";
    };

    config = lib.mkIf config.mine.nvidia.enable { 
      
      environment.sessionVariables = {
        # Wayland Nvidia disappearing cursor fix
        WLR_NO_HARDWARE_CURSORS = "1";
      };
      environment.systemPackages = with pkgs; [ libva ];

      hardware.opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true;
      };

      hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = false; # changed from default false (back to false for testing)
        powerManagement.finegrained = false;
        open = false;
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.stable;
      };

      services.xserver = {
        videoDrivers = ["nvidia"];
      };
    };
}