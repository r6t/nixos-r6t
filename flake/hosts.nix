{ config, ... }:

let
  discovery = import ./discovery.nix;
  hostNames = discovery.flakeModuleDirs ../hosts;
  mkNixosHost = config.flake.lib.mkRegisteredNixosHost;
in
{
  flake.nixosConfigurations = builtins.listToAttrs
    (map (name: { inherit name; value = mkNixosHost name; }) hostNames);
}
