{ lib, config, pkgs, ... }: {

  options = {
    mine.env.enable =
      lib.mkEnableOption "enable linux baseline utilities";
  };

  config = lib.mkIf config.mine.env.enable {
    environment.shells = with pkgs; [ fish ]; # /etc/shells
    # System packages
    environment.systemPackages = with pkgs; [
      bat
      cryptsetup
      curl
      dig
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
