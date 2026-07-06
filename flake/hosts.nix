{ config, inputs, self, ... }:

let
  inherit (import ./common.nix) userConfig;
  inherit (self) outputs;

  specialArgs = { inherit userConfig inputs outputs; isNixOS = true; };

  mkNixosHost = name: inputs.nixpkgs.lib.nixosSystem {
    inherit specialArgs;
    modules = [ config.flake.modules.nixos.${name} ];
  };
in
{
  flake.nixosConfigurations = {
    # cold storage
    barrel = mkNixosHost "barrel";

    # primary server
    crown = mkNixosHost "crown";

    mountainball = mkNixosHost "mountainball";

    # laptop — ASUS ROG Z13 GZ302 Strix Halo
    goldenball = mkNixosHost "goldenball";

    # living room HTPC — gamescope session + image generation
    hedgehog = mkNixosHost "hedgehog";

    # router + appliances
    saguaro = mkNixosHost "saguaro";
  };
}
