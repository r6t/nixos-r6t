{
  flake.modules.nixos.kde-workstation = { ... }: {
    imports = [
      ../../flatpak/anki/options.nix
      ../../flatpak/anki/config.nix
      ../../flatpak/base/options.nix
      ../../flatpak/base/config.nix
      ../../flatpak/calibre/options.nix
      ../../flatpak/calibre/config.nix
      ../../flatpak/element/options.nix
      ../../flatpak/element/config.nix
      ../../flatpak/inkscape/options.nix
      ../../flatpak/inkscape/config.nix
      ../../flatpak/libreoffice/options.nix
      ../../flatpak/libreoffice/config.nix
      ../../flatpak/picard/options.nix
      ../../flatpak/picard/config.nix
      ../../flatpak/proton-mail/options.nix
      ../../flatpak/proton-mail/config.nix
      ../../flatpak/remmina/options.nix
      ../../flatpak/remmina/config.nix
      ../../flatpak/zoom/options.nix
      ../../flatpak/zoom/config.nix
      ../../home/alacritty/options.nix
      ../../home/alacritty/config.nix
      ../../home/bitwarden/options.nix
      ../../home/bitwarden/config.nix
      ../../home/browsers/options.nix
      ../../home/browsers/config.nix
      ../../home/darktable/options.nix
      ../../home/darktable/config.nix
      ../../home/drawio/options.nix
      ../../home/drawio/config.nix
      ../../home/fontconfig/options.nix
      ../../home/fontconfig/config.nix
      ../../home/kde-apps/options.nix
      ../../home/kde-apps/config.nix
      ../../home/mpv/options.nix
      ../../home/mpv/config.nix
      ../../home/obsidian/options.nix
      ../../home/obsidian/config.nix
      ../../home/signal-desktop/options.nix
      ../../home/signal-desktop/config.nix
      ../../home/teams-for-linux/options.nix
      ../../home/teams-for-linux/config.nix
      ../../home/webcord/options.nix
      ../../home/webcord/config.nix
      ../../nixos/bluetooth/options.nix
      ../../nixos/bluetooth/config.nix
      ../../nixos/czkawka/options.nix
      ../../nixos/czkawka/config.nix
      ../../nixos/direnv/options.nix
      ../../nixos/direnv/config.nix
      ../../nixos/fonts/options.nix
      ../../nixos/fonts/config.nix
      ../../nixos/kde/options.nix
      ../../nixos/kde/config.nix
      ../../nixos/networkmanager/options.nix
      ../../nixos/networkmanager/config.nix
      ../../nixos/npm/options.nix
      ../../nixos/npm/config.nix
      ../../nixos/printing/options.nix
      ../../nixos/printing/config.nix
      ../../nixos/sound/options.nix
      ../../nixos/sound/config.nix
      ../../nixos/v4l-utils/options.nix
      ../../nixos/v4l-utils/config.nix
      ../../nixos/zola/options.nix
      ../../nixos/zola/config.nix
    ];

    nixpkgs.config = {
      allowUnfree = true;
      # Temporary allow recent EOL Electron packages used by desktop apps.
      permittedInsecurePackages = [ "electron-36.9.5" "electron-39.8.10" ];
    };
  };
}
