{
  flake.modules.nixos.kde-workstation = { lib, ... }: {
    imports = [
      ../../home/alacritty/config.nix
      ../../home/bitwarden/config.nix
      ../../home/drawio/config.nix
      ../../home/fontconfig/config.nix
      ../../home/mpv/config.nix
      ../../home/obsidian/config.nix
      ../../home/signal-desktop/config.nix
      ../../home/teams-for-linux/config.nix
      ../../home/webcord/config.nix
      ../../nixos/bluetooth/config.nix
      ../../nixos/czkawka/config.nix
      ../../nixos/direnv/config.nix
      ../../nixos/fonts/config.nix
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

    mine = {
      flatpak = {
        base.enable = lib.mkDefault true;
        anki.enable = lib.mkDefault true;
        calibre.enable = lib.mkDefault true;
        element.enable = lib.mkDefault true;
        inkscape.enable = lib.mkDefault true;
        libreoffice.enable = lib.mkDefault true;
        picard.enable = lib.mkDefault true;
        proton-mail.enable = lib.mkDefault true;
        remmina.enable = lib.mkDefault true;
        zoom.enable = lib.mkDefault true;
      };

      home = {
        browsers.enable = lib.mkDefault true;
        darktable.enable = lib.mkDefault true;
        kde-apps.enable = lib.mkDefault true;
      };

      kde.enable = lib.mkDefault true;
    };
  };
}
