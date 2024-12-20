{
  inputs,
  userConfig,
  ...
}:

 {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.sops-nix.nixosModules.sops
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  # system details
  networking.hostName = "saguaro";
  networking.firewall.allowedTCPPorts = [ 
    22
    8096 # jellyfin
    8920 # jellyfin
    5201 # iperf
    8080 # stirling-pdf
    8384 # syncthing
    19999 # netdata
    22000 # syncthing
    6595
    8888
    9090
    9999
    7878
    8686
    8989
    ];
  networking.firewall.allowedUDPPorts = [ 
    1900 # jellyfin
    7359 # jellyfin
    5353
    ];
  system.stateVersion = "23.11";
  
  users.users.${userConfig.username}.linger = true;

  # system modules
  mine.bolt.enable = true;
  mine.bootloader.enable = true;
  mine.docker.enable = true;
  mine.env.enable = true;
  mine.fwupd.enable = true;
  mine.fzf.enable = true;
  mine.immich.enable = true;
  mine.iperf.enable = true;
  mine.localization.enable = true;
  mine.netdata.enable = true;
  mine.networkmanager.enable = true;
  mine.nix.enable = true;
  mine.nixpkgs.enable = true;
  mine.nvidia.enable = true;
  mine.ollama.enable = false;
  mine.open-webui.enable = true;
  mine.paperless.enable = true;
  mine.selfhost.enable = false;
  mine.sops.enable = true;
  mine.ssh.enable = true;
  mine.syncthing.enable = true;
  mine.tailscale.enable = true;
  mine.thunderbay.enable = true;
  mine.user.enable = true;

  # home modules
  mine.home.awscli.enable = true;
  mine.home.fish.enable = true;
  mine.home.git.enable = true;
  mine.home.home-manager.enable = true;
  mine.home.nixvim.enable = true;
  mine.home.python3.enable = true;
  mine.home.yt-dlp.enable = true;
}
