{ inputs, lib, config, pkgs, userConfig, ... }: {

  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.home.home-manager.enable
    (import ./config.nix { inherit inputs lib pkgs userConfig; });
}
