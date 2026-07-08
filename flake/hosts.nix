{ config, ... }:

let
  mkNixosHost = config.flake.lib.mkRegisteredNixosHost;
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

    # router + appliances
    saguaro = mkNixosHost "saguaro";
  };
}
