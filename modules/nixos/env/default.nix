{ lib, config, pkgs, ... }: { 

    options = {
      mine.env.enable =
        lib.mkEnableOption "enable my environment defaults";
    };

    config = lib.mkIf config.mine.env.enable { 
      environment.shells = with pkgs; [ zsh ]; # /etc/shells
      # System packages
      environment.systemPackages = with pkgs; [
         arion
         curl
         cryptsetup
         fd
         git
         git-remote-codecommit
         home-manager
         lshw
         neovim
         neofetch
         netcat
         netdata
         nmap
         nodejs
         openssl
         pciutils
         ripgrep
         sops
         tmux
         unzip
         usbutils
         wget
         tree
      ];
    };
}