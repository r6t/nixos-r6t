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
      cryptsetup
      curl
      dig
      fd
      ffmpeg
      git
      git-remote-codecommit
      gnumake
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
      tree
      unzip
      usbutils
      wget
      zip
    ];
  };
}
