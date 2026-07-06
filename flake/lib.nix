{ config, inputs, self, ... }:

let
  inherit (import ./common.nix) userConfig;
  inherit (self) outputs;

  defaultSpecialArgs = { inherit userConfig inputs outputs; isNixOS = true; };

  mkNixosHost =
    { modules
    , specialArgs ? defaultSpecialArgs
    ,
    }:
    inputs.nixpkgs.lib.nixosSystem {
      inherit modules specialArgs;
    };
in
{
  flake.lib = {
    inherit mkNixosHost;

    mkRegisteredNixosHost = name: mkNixosHost {
      modules = [ config.flake.modules.nixos.${name} ];
    };
  };
}
