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

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
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

  outputs = { self, nixpkgs, pre-commit-hooks, ... } @inputs:
    let
      userConfig = {
        username = "r6t";
        homeDirectory = "/home/r6t";
      };
      inherit (self) outputs;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = {
        # nixos networking device
        exit-node = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs userConfig; };
          modules = [ ./hosts/exit-node/configuration.nix ];
        };
        # nixos laptop
        mountainball = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs userConfig; };
          modules = [ ./hosts/mountainball/configuration.nix ];
        };
        # nixos server
        saguaro = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs outputs userConfig; };
          modules = [ ./hosts/saguaro/configuration.nix ];
        };
      };

      checks.${system} = {
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixpkgs-fmt.enable = true;
            statix.enable = true;
            deadnix.enable = true;
          };
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        inherit (self.checks.${system}.pre-commit-check) shellHook;
        buildInputs = with pkgs; [
          pre-commit
        ];
      };
    };
}
