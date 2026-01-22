{ lib, config, pkgs, ... }: {

  options = {
    mine.nixos-r6t-baseline.enable =
      lib.mkEnableOption "enable NixOS baseline system configuration";
  };

  config = lib.mkIf config.mine.nixos-r6t-baseline.enable {
    # Enable fish shell system-wide
    programs.fish.enable = true;
    
    # Add fish to /etc/shells
    environment.shells = with pkgs; [ fish ];
    
    # System packages
    environment.systemPackages = with pkgs; [
      bat
      cryptsetup
      curl
      dig
      ethtool
      fd
      ffmpeg
      git
      git-remote-codecommit
      gnumake
      home-manager
      htop
      inetutils
      lshw
      neovim
      netcat
      nmap
      openssl
      pciutils
      python314
      ripgrep
      sops
      tcpdump
      tmux
      tree
      unzip
      usbutils
      wget
      wireguard-tools
      zip
    ];
  };
}
