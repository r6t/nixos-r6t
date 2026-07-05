{ config, ... }:

{
  flake.nixosModules = {
    default = config.flake.modules.nixos.default;
  };
}
