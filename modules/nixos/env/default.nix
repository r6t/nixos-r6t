{ lib, config, pkgs, ... }: { 

    options = {
      mine.env.enable =
        lib.mkEnableOption "enable my environment defaults";
    };

    config = lib.mkIf config.mine.env.enable { 
      environment.shells = with pkgs; [ zsh ]; # /etc/shells
      # System packages
      environment.systemPackages = with pkgs; [
         curl
         cryptsetup
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