{
  flake.modules.nixos.kde-workstation = { ... }: {
    imports = [
      ../../flatpak/anki/config.nix
      ../../flatpak/base/config.nix
      ../../flatpak/calibre/config.nix
      ../../flatpak/element/config.nix
      ../../flatpak/inkscape/config.nix
      ../../flatpak/libreoffice/config.nix
      ../../flatpak/picard/config.nix
      ../../flatpak/proton-mail/config.nix
      ../../flatpak/remmina/config.nix
      ../../flatpak/zoom/config.nix
      ../../home/alacritty/config.nix
      ../../home/bitwarden/config.nix
      ../../home/browsers/config.nix
      ../../home/darktable/config.nix
      ../../home/drawio/config.nix
      ../../home/fontconfig/config.nix
      ../../home/kde-apps/config.nix
      ../../home/mpv/config.nix
      ../../home/obsidian/config.nix
      ../../home/signal-desktop/config.nix
      ../../home/teams-for-linux/config.nix
      ../../home/webcord/config.nix
      ../../nixos/bluetooth/config.nix
      ../../nixos/czkawka/config.nix
      ../../nixos/direnv/config.nix
      ../../nixos/fonts/config.nix
      ../../nixos/kde/config.nix
      ../../nixos/networkmanager/config.nix
      ../../nixos/npm/config.nix
      ../../nixos/printing/config.nix
      ../../nixos/sound/config.nix
      ../../nixos/v4l-utils/config.nix
      ../../nixos/zola/config.nix
    ];

    nixpkgs.config = {
      allowUnfree = true;
      # Temporary allow recent EOL Electron packages used by desktop apps.
      permittedInsecurePackages = [ "electron-36.9.5" "electron-39.8.10" ];
    };
  };
}
