{ inputs, pkgs, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    inputs.nix-flatpak.nixosModules.nix-flatpak
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  environment.systemPackages = with pkgs; [ refind ];
  time.timeZone = "America/Los_Angeles";

  networking = {
    hostName = "silvertorch";
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
    config.common.default = "kde";
  };

  swapDevices = [
    {
      device = "/swapfile";
      size = 4096;
    }
  ];

  system.activationScripts.refindSetup = {
    text = ''
      mkdir -p /boot/EFI/refind
      cp -r ${pkgs.refind}/share/refind/* /boot/EFI/refind/
      
      # Copy only necessary drivers
      cp ${pkgs.refind}/share/refind/drivers_x64/ext4_x64.efi /boot/EFI/refind/drivers/
      cp ${pkgs.refind}/share/refind/drivers_x64/btrfs_x64.efi /boot/EFI/refind/drivers/
      
      # Create config
      cat > /boot/EFI/refind/refind.conf <<EOF
      timeout 3
      scanfor manual
      hideui singleuser,hints,badges
      
      menuentry "NixOS" {
        loader /EFI/nixos/systemd-bootx64.efi
        icon /EFI/refind/icons/os_nixos.png
      }
      
      menuentry "Bazzite OS" {
        loader /EFI/Bazzite/grubx64.efi
        icon /EFI/refind/icons/os_linux.png
      }
      EOF
    '';
    deps = [ ];
  };
  system.stateVersion = "23.11";

  systemd.services.create-refind-entry = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.efibootmgr}/bin/efibootmgr -c \
        -d /dev/nvme1n1 \
        -p 1 \
        -L "rEFInd" \
        -l '\EFI\refind\refind_x64.efi' \
        --verbose
    '';
  };
  environment.etc."EFI/refind/refind.conf".source = "/boot/EFI/refind/refind.conf";
  services.fprintd.enable = false;

  # Toggle modules
  mine = {
    flatpak = {
      anki.enable = true;
      calibre.enable = true;
      deezer.enable = true;
      element.enable = true;
      inkscape.enable = true;
      jellyfin-player.enable = true;
      kamoso.enable = true;
      libreoffice.enable = true;
      picard.enable = true;
      proton-mail.enable = true;
      protonup-qt.enable = true;
      remmina.enable = true;
      steam.enable = true;
      supersonic.enable = true;
      zoom.enable = true;
    };

    home = {
      alacritty.enable = true;
      atuin.enable = true;
      awscdk.enable = true;
      awscli.enable = true;
      bitwarden.enable = true;
      browsers.enable = true;
      darktable.enable = true;
      drawio.enable = true;
      fish.enable = true;
      fontconfig.enable = true;
      freecad.enable = true;
      git.enable = true;
      home-manager.enable = true;
      kde-apps.enable = true;
      mpv.enable = true;
      nixvim.enable = true;
      obsidian.enable = true;
      obs-studio.enable = true;
      python3.enable = true;
      signal-desktop.enable = true;
      ssh.enable = true;
      virt-viewer.enable = true;
      webcord.enable = true;
      yt-dlp.enable = true;
      zellij.enable = true;
    };

    bluetooth.enable = true;
    bootloader.enable = false;
    czkawka.enable = true;
    docker.enable = true;
    env.enable = true;
    fonts.enable = true;
    fwupd.enable = true;
    fzf.enable = true;
    iperf.enable = true;
    kde.enable = true;
    localization.enable = true;
    networkmanager.enable = true;
    nix.enable = true;
    nixpkgs.enable = true;
    nvidia-open.enable = true;
    ollama-cuda.enable = true;
    printing.enable = true;
    prometheus-node-exporter.enable = true;
    rdfind.enable = true;
    scansnap.enable = true;
    sops.enable = true;
    sound.enable = true;
    ssh.enable = true;
    sshfs.enable = true;
    syncthing.enable = true;
    tailscale.enable = true;
    tpm.enable = true;
    user.enable = true;
    v4l-utils.enable = true;
  };
}
