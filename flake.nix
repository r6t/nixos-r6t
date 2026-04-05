{
  description = "r6t nixos systems configuration flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hardware.url = "github:nixos/nixos-hardware";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
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
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ssh-keys = {
      url = "https://github.com/r6t.keys";
      flake = false;
    };
  };

  outputs = { self, nixos-generators, nixpkgs, flake-utils, pre-commit-hooks, ... } @inputs:
    let
      userConfig = {
        username = "r6t";
        homeDirectory = "/home/r6t";
      };
      inherit (self) outputs;
      linuxSystem = "x86_64-linux";
    in
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-darwin" ]
      (system:
        {
          # Devshells for both Linux and macOS
          devShells = import ./devshells.nix {
            pkgs = import nixpkgs { inherit system; };
            inherit self nixpkgs;
          };
        }
      ) // {
      # Bare-metal hosts
      nixosConfigurations = {
        # cold storage
        barrel = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit userConfig inputs outputs; isNixOS = true; };
          modules = [
            ./hosts/barrel/configuration.nix
          ];
        };
        # primary server
        crown = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit userConfig inputs outputs; isNixOS = true; };
          modules = [
            ./hosts/crown/configuration.nix
            {
              nixpkgs.config = {
                allowUnfree = true;
                cudaSupport = true;
                nvidia.acceptLicense = true;
              };
            }
          ];
        };
        mountainball = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit userConfig inputs outputs; isNixOS = true; };
          modules = [
            ./hosts/mountainball/configuration.nix
            {
              nixpkgs.config = {
                allowUnfree = true;
                # temporary allow recent EOL
                permittedInsecurePackages = [ "electron-36.9.5" ];
              };
            }
          ];
        };
        # router + appliances
        saguaro = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit userConfig inputs outputs; isNixOS = true; };
          modules = [
            ./hosts/saguaro/configuration.nix
          ];
        };
      };

      # Container images — auto-generated from containers/*.nix
      # Each file produces two outputs: {name} (rootfs) and {name}-metadata
      # Build with: nix build .#<name>  or  nix build .#<name>-metadata
      packages.${linuxSystem} =
        let
          containerDir = ./containers;
          containerFiles = builtins.filter
            (f: nixpkgs.lib.hasSuffix ".nix" f)
            (builtins.attrNames (builtins.readDir containerDir));

          mkImage = file:
            let
              name = builtins.replaceStrings [ ".nix" ] [ "" ] file;
              module = containerDir + "/${file}";
            in
            [
              {
                inherit name;
                value = nixos-generators.nixosGenerate {
                  system = linuxSystem;
                  format = "lxc";
                  modules = [ module ];
                  specialArgs = { inherit outputs userConfig inputs; };
                };
              }
              {
                name = "${name}-metadata";
                value = nixos-generators.nixosGenerate {
                  system = linuxSystem;
                  format = "lxc-metadata";
                  modules = [ module ];
                  specialArgs = { inherit outputs userConfig inputs; };
                };
              }
            ];
        in
        builtins.listToAttrs (builtins.concatMap mkImage containerFiles);

      # Pre-commit
      checks.${linuxSystem} = {
        pre-commit-check = pre-commit-hooks.lib.${linuxSystem}.run {
          src = ./.;
          hooks = {
            nixpkgs-fmt.enable = true;
            statix = {
              enable = true;
              settings = {
                ignore = [
                  "hosts/crown/hardware-configuration.nix"
                  "hosts/mountainball/hardware-configuration.nix"
                  "hosts/saguaro/configuration.nix"
                ];
              };
            };
            deadnix = {
              enable = true;
              excludes = [ ".*hardware-configuration\\.nix$" ];
            };
            prettier.enable = true;
            black.enable = true;
            isort.enable = true;
            eslint.enable = true;
            pylint.enable = true;
          };
        };
      };

      # Export home-manager modules for use by other flakes (e.g., nix-work-r6t)
      # These portable modules work on any system (NixOS, macOS, other Linux)
      homeManagerModules = {
        fish = import ./modules/home/fish/default.nix;
        nixvim = import ./modules/home/nixvim/default.nix;
        zellij = import ./modules/home/zellij/default.nix;
        git = import ./modules/home/git/default.nix;
        atuin = import ./modules/home/atuin/default.nix;
        alacritty = import ./modules/home/alacritty/default.nix;
      };
    };
}

