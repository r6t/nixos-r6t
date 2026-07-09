{ lib, config, pkgs, userConfig, ... }: {

  imports = [ ./options.nix ];

  # nixpkgs.config.allowUnfree is set at the host level in flake.nix
  config = lib.mkIf config.mine.home.obsidian.enable
    (import ./config.nix { inherit pkgs userConfig; });
}
