{ config, inputs, lib, self, ... }:

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
  config = {
    flake.lib = {
      inherit mkNixosHost;

      mkRegisteredNixosHost = name: mkNixosHost {
        modules = [ config.flake.modules.nixos.${name} ];
        specialArgs = defaultSpecialArgs // (config.nixosHostSpecialArgs.${name} or { });
      };
    };
  };

  options.nixosHostSpecialArgs = lib.mkOption {
    type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
    default = { };
    description = "Per-host specialArgs merged over the flake defaults for nixosSystem.";
  };
}
