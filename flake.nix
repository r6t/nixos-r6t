{
  description = "r6t nixos systems configuration flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      # url = "github:nix-community/home-manager/master"; nixos-unstable
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hardware.url = "github:nixos/nixos-hardware";

    nixvim = {
        url = "github:nix-community/nixvim/nixos-24.05";
        # url = "github:nix-community/nixvim"; nixos-unstable
        inputs.nixpkgs.follows = "nixpkgs";
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

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    nixvim,
    home-manager,
    sops-nix,
    ...
  } @ inputs: let
    inherit (self) outputs;

      allowUnfreeOverlay = final: prev: {
        nixpkgs.config = {
          allowUnfree = true;
        };
      };

      pkgsUnstable = import nixpkgs-unstable {
        overlays = [ allowUnfreeOverlay ];
        config = { allowUnfree = true; };
      };
  in {
    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild --flake .#your-hostname'
    nixosConfigurations = {
      # laptop
      mountainball = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [./hosts/mountainball/configuration.nix];
      };
      # utility server
      starfish = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [./hosts/starfish/configuration.nix];
      };
      # main server
      saguaro = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [./hosts/saguaro/configuration.nix];
      };
      # htpc
      silvertorch = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          ./hosts/silvertorch/configuration.nix
        ];
      };
    };
  };
}
