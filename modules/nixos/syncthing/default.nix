{ lib, config, userConfig, ... }:

{
  options = {
    mine.syncthing.enable = lib.mkEnableOption "enable and configure my syncthing";
  };

  config = lib.mkIf config.mine.syncthing.enable (import ./config.nix { inherit lib config userConfig; });
}
