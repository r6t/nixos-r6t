{ config, inputs, ... }:

let
  # Stable compatibility API for downstream flakes. Keep these names available
  # even if the internal module layout moves toward dendritic feature modules.
  portableHomeManagerModules = config.flake.modules.homeManager;
in
{
  flake.homeManagerModules = portableHomeManagerModules // {
    default = {
      imports = [
        inputs.nixvim.homeModules.nixvim
      ] ++ builtins.attrValues portableHomeManagerModules;
    };
  };
}
