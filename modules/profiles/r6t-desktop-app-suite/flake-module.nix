{ inputs, ... }:

let
  flatpakModules = import ../../flatpak/modules.nix;
  workstationFlatpaks = [
    "anki"
    "calibre"
    "element"
    "kamoso"
    "libreoffice"
    "picard"
    "proton-mail"
    "remmina"
    "zoom"
  ];
  enabledWorkstationFlatpaks = builtins.listToAttrs (map
    (name: {
      inherit name;
      value.enable = true;
    })
    workstationFlatpaks);
in
{
  flake.modules.nixos.r6t-desktop-app-suite = { ... }: {
    imports =
      [
        inputs.self.modules.nixos.desktop-home-core
        inputs.nix-flatpak.nixosModules.nix-flatpak
        inputs.sops-nix.nixosModules.sops
      ]
      ++ (map (name: ../../flatpak/${name}/default.nix) flatpakModules)
      ++ [
        ../../home/bitwarden/options.nix
        ../../home/bitwarden/config.nix
        ../../home/darktable/options.nix
        ../../home/darktable/config.nix
        ../../home/drawio/options.nix
        ../../home/drawio/config.nix
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
        ../../nixos/czkawka/options.nix
        ../../nixos/czkawka/config.nix
        ../../nixos/direnv/options.nix
        ../../nixos/direnv/config.nix
        ../../nixos/npm/options.nix
        ../../nixos/npm/config.nix
        ../../nixos/zola/options.nix
        ../../nixos/zola/config.nix
      ];

    # Shared workstation Flatpaks. Hosts can use lib.mkForce false on individual
    # mine.flatpak.<name>.enable options to avoid cross-host duplication.
    mine.flatpak = { base.enable = true; } // enabledWorkstationFlatpaks;

    # Temporary allow recent EOL Electron packages used by desktop apps.
    nixpkgs.config.permittedInsecurePackages = [ "electron-36.9.5" "electron-39.8.10" ];
  };
}
