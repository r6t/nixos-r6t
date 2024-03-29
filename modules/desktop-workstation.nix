{ pkgs, lib, ...}: {

    imports = [
      apps/flatpak/default.nix
      apps/hypr/default.nix
      apps/mullvad/default.nix
      
      system/bluetooth/default.nix
      system/env/default.nix
      system/fonts/default.nix
      system/printing/default.nix
      system/sound/default.nix
    ];
}