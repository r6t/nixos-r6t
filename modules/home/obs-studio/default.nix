{ lib, config, userConfig, ... }: {

  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.home.obs-studio.enable
    (import ./config.nix { inherit userConfig; });
}
