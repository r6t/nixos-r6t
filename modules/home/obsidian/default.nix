{ lib, config, pkgs, userConfig, ... }: {

  options = {
    mine.home.obsidian.enable =
      lib.mkEnableOption "enable obsidian in home-manager";
  };

  # nixpkgs.config.allowUnfree is set at the host level in flake.nix
  config = lib.mkIf config.mine.home.obsidian.enable
    (import ./config.nix { inherit pkgs userConfig; });
}
