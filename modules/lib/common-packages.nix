# Packages shared between bare-metal hosts (nixos-r6t-baseline) and LXC containers (base.nix).
# Each consumer adds their own extras on top.
pkgs: with pkgs; [
  curl
  dig
  ethtool
  fd
  git
  git-remote-codecommit
  gnumake
  htop
  lshw
  neovim
  netcat
  nmap
  openssl
  pciutils
  ripgrep
  tcpdump
  tree
  unzip
  usbutils
  wget
  zip
]
