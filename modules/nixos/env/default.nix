{ lib, config, pkgs, ... }: { 

    options = {
      mine.env.enable =
        lib.mkEnableOption "enable general utilities";
    };

    config = lib.mkIf config.mine.env.enable { 
      environment.shells = with pkgs; [ zsh ]; # /etc/shells
      # System packages
      environment.systemPackages = with pkgs; [
         arion
         curl
         cryptsetup
         dig
         fd
         git
         git-remote-codecommit
         home-manager
         lshw
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
