{
  flake.modules.nixos.desktop-home-core = { ... }: {
    imports = [
      ../../home/alacritty/options.nix
      ../../home/alacritty/config.nix
      ../../home/browsers/options.nix
      ../../home/browsers/config.nix
      ../../home/fontconfig/options.nix
      ../../home/fontconfig/config.nix
      ../../home/kde-apps/options.nix
      ../../home/kde-apps/config.nix
      ../../nixos/sops/options.nix
    ];
  };
}
