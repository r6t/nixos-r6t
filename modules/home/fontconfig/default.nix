{ lib, config, userConfig, ... }: {

  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.home.fontconfig.enable
    (import ./config.nix { inherit userConfig; });
}
