{ lib, config, pkgs, ... }: { 

    options = {
      mine.env.enable =
        lib.mkEnableOption "enable general utilities";
    };

    config = lib.mkIf config.mine.env.enable { 
      environment.shells = with pkgs; [ fish ]; # /etc/shells
      # System packages
      environment.systemPackages = with pkgs; [
         arion
         bat
         curl
         cryptsetup
         dig
         fd
         ffmpeg
         git
         git-remote-codecommit
         home-manager
         inetutils
         lshw
         neovim
         netcat
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
