{ inputs, self, ... }:

let
  inherit (import ./common.nix) userConfig;
  inherit (self) outputs;

  specialArgs = { inherit userConfig inputs outputs; isNixOS = true; };

  allowUnfreeWithTemporaryElectronInsecure = {
    nixpkgs.config = {
      allowUnfree = true;
      # temporary allow recent EOL
      permittedInsecurePackages = [ "electron-36.9.5" "electron-39.8.10" ];
    };
  };
in
{
  flake.nixosConfigurations = {
    # cold storage
    barrel = inputs.nixpkgs.lib.nixosSystem {
      inherit specialArgs;
      modules = [
        ../hosts/barrel/configuration.nix
      ];
    };

    # primary server
    crown = inputs.nixpkgs.lib.nixosSystem {
      inherit specialArgs;
      modules = [
        ../hosts/crown/configuration.nix
      ];
    };

    mountainball = inputs.nixpkgs.lib.nixosSystem {
      inherit specialArgs;
      modules = [
        ../hosts/mountainball/configuration.nix
        allowUnfreeWithTemporaryElectronInsecure
      ];
    };

    # laptop — ASUS ROG Z13 GZ302 Strix Halo
    goldenball = inputs.nixpkgs.lib.nixosSystem {
      inherit specialArgs;
      modules = [
        ../hosts/goldenball/configuration.nix
        allowUnfreeWithTemporaryElectronInsecure
      ];
    };

    # living room HTPC — gamescope session + image generation
    hedgehog = inputs.nixpkgs.lib.nixosSystem {
      inherit specialArgs;
      modules = [
        ../hosts/hedgehog/configuration.nix
        {
          nixpkgs.config = {
            allowUnfree = true;
            cudaSupport = true;
          };
        }
      ];
    };

    # router + appliances
    saguaro = inputs.nixpkgs.lib.nixosSystem {
      inherit specialArgs;
      modules = [
        ../hosts/saguaro/configuration.nix
      ];
    };
  };
}
