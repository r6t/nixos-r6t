{ lib, config, userConfig, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.syncthing.enable (import ./config.nix { inherit lib config userConfig; });
}
