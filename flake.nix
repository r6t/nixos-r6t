{
  description = "r6t nixos systems configuration flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hardware.url = "github:nixos/nixos-hardware";

    nix-flatpak = {
      url = "github:gmodena/nix-flatpak";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    sops-ryan = {
      url = "git+https://git-codecommit.us-west-2.amazonaws.com/v1/repos/sops-ryan?ref=main";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ssh-keys = {
      url = "https://github.com/r6t.keys";
      flake = false;
    };
  };

  outputs = {self, nixpkgs, home-manager, ... } @inputs:
  let
    inherit (self) outputs;
    userConfig = import ./user-config.nix;
  in {
    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild --flake .#your-hostname'
    nixosConfigurations = {
      # nixos networking device
      exit-node = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs userConfig;};
        modules = [./hosts/exit-node/configuration.nix];
      };
      # nixos laptop
      mountainball = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs userConfig;};
        modules = [./hosts/mountainball/configuration.nix];
      };
      # nixos server
      saguaro = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs userConfig;};
        modules = [./hosts/saguaro/configuration.nix];
      };
    };
  };
}
