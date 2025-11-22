{
  description = "r6t nixos systems configuration flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
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
    plasma-manager.url = "github:nix-community/plasma-manager";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ssh-keys = {
      url = "https://github.com/r6t.keys";
      flake = false;
    };
  };

  outputs = { self, nixos-generators, nixpkgs, pre-commit-hooks, ... } @inputs:
    let
      userConfig = {
        username = "r6t";
        homeDirectory = "/home/r6t";
      };
      inherit (self) outputs;
      system = "x86_64-linux";
    in
    {
      # Bare-metal hosts
      nixosConfigurations = {
        crown = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit userConfig inputs outputs; };
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
          specialArgs = { inherit userConfig inputs outputs; };
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
        saguaro = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit userConfig inputs outputs; };
          modules = [
            ./hosts/saguaro/configuration.nix
          ];
        };
      };

      # Container images
      packages.${system} = {
        docker = nixos-generators.nixosGenerate {
          inherit system;
          format = "lxc";
          modules = [ ./containers/docker.nix ];
          specialArgs = { inherit outputs userConfig inputs; };
        };
        dockerMetadata = nixos-generators.nixosGenerate {
          inherit system;
          format = "lxc-metadata";
          modules = [ ./containers/docker.nix ];
          specialArgs = { inherit outputs userConfig inputs; };
        };
        dns = nixos-generators.nixosGenerate {
          inherit system;
          format = "lxc";
          modules = [ ./containers/dns.nix ];
          specialArgs = { inherit outputs userConfig inputs; };
        };
        dnsMetadata = nixos-generators.nixosGenerate {
          inherit system;
          format = "lxc-metadata";
          modules = [ ./containers/dns.nix ];
          specialArgs = { inherit outputs userConfig inputs; };
        };
        headscale = nixos-generators.nixosGenerate {
          inherit system;
          format = "lxc";
          modules = [ ./containers/headscale.nix ];
          specialArgs = { inherit outputs userConfig inputs; };
        };
        headscaleMetadata = nixos-generators.nixosGenerate {
          inherit system;
          format = "lxc-metadata";
          modules = [ ./containers/headscale.nix ];
          specialArgs = { inherit outputs userConfig inputs; };
        };
        immich = nixos-generators.nixosGenerate {
          inherit system;
          format = "lxc";
          modules = [ ./containers/immich.nix ];
          specialArgs = { inherit outputs userConfig inputs; };
        };
        immichMetadata = nixos-generators.nixosGenerate {
          inherit system;
          format = "lxc-metadata";
          modules = [ ./containers/immich.nix ];
          specialArgs = { inherit outputs userConfig inputs; };
        };
        llm = nixos-generators.nixosGenerate {
          inherit system;
          format = "lxc";
          modules = [ ./containers/llm.nix ];
          specialArgs = { inherit outputs userConfig inputs; };
        };
        llmMetadata = nixos-generators.nixosGenerate {
          inherit system;
          format = "lxc-metadata";
          modules = [ ./containers/llm.nix ];
          specialArgs = { inherit outputs userConfig inputs; };
        };
        monitoring = nixos-generators.nixosGenerate {
          inherit system;
          format = "lxc";
          modules = [ ./containers/monitoring.nix ];
          specialArgs = { inherit outputs userConfig inputs; };
        };
        monitoringMetadata = nixos-generators.nixosGenerate {
          inherit system;
          format = "lxc-metadata";
          modules = [ ./containers/monitoring.nix ];
          specialArgs = { inherit outputs userConfig inputs; };
        };
        tailnetExit = nixos-generators.nixosGenerate {
          inherit system;
          format = "lxc";
          modules = [ ./containers/tailnet-exit.nix ];
          specialArgs = { inherit outputs userConfig inputs; };
        };
        tailnetExitMetadata = nixos-generators.nixosGenerate {
          inherit system;
          format = "lxc-metadata";
          modules = [ ./containers/tailnet-exit.nix ];
          specialArgs = { inherit outputs userConfig inputs; };
        };
      };

      # Pre-commit
      checks.${system} = {
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixpkgs-fmt.enable = true;
            statix = {
              enable = true;
              settings = {
                ignore = [
                  "hosts/crown/hardware-configuration.nix"
                  "hosts/mountainball/hardware-configuration.nix"
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

      # Devshells managed in dedicated file
      devShells.${system} = import ./devshells.nix {
        pkgs = import nixpkgs { inherit system; };
        inherit self nixpkgs;
      };
    };
}

