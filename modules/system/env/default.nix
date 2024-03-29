{ lib, config, pkgs, ... }: { 

    options = {
      mine.env.enable =
        lib.mkEnableOption "enable my environment defaults";
    };

    config = lib.mkIf config.mine.env.enable { 
      # Env vars currently included in base-system
      environment.sessionVariables = {
        NIXOS_OZONE_WL = "1";
        QT_STYLE_OVERRIDE = "Breeze-Dark";
        # Wayland Nvidia disappearing cursor fix
        WLR_NO_HARDWARE_CURSORS = "1";
    
      };
      environment.shells = with pkgs; [ zsh ]; # /etc/shells
      # System packages
      environment.systemPackages = with pkgs; [
         ansible
         curl
         fd
         git
         home-manager
         lshw
         neovim
         neofetch
         netdata
         nmap
         nodejs
         pciutils
         ripgrep
         tmux
         unzip
         usbutils
         wget
         tree
      ];
    };
}