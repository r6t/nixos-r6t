{
  description = "r6t nixos system config";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hardware.url = "github:nixos/nixos-hardware";

    nixvim = {
      url = "github:nix-community/nixvim/nixos-23.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ssh-keys approach copied from https://github.com/borgstad/nixos-config/
    ssh-keys = {
      url = "https://github.com/r6t.keys";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager, # maybe not needed since removing homeConfigurations?
    ...
  } @ inputs: let
    inherit (self) outputs;
  in {
    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild --flake .#your-hostname'
    nixosConfigurations = {
      # vm server
      beehive = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [./nixos/beehive-configuration.nix];
      };
      # desktop
      mountainball = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [./nixos/mountainball-configuration.nix];
      };
      # container server
      saguaro = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [./nixos/saguaro-configuration.nix];
      };
      # laptop
      silvertorch = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [./nixos/silvertorch-configuration.nix];
      };
    };
  };
}
