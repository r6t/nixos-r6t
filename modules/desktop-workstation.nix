{ pkgs, lib, ...}: {

    imports = [
      nixos/flatpak/default.nix
      nixos/hypr/default.nix
      nixos/mullvad/default.nix
      nixos/steam/default.nix
      
      nixos/bluetooth/default.nix
      nixos/fonts/default.nix
      nixos/printing/default.nix
      nixos/sound/default.nix
    ];
}