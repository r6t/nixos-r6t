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
        # cold storage
        barrel = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit userConfig inputs outputs; };
          modules = [
            ./hosts/barrel/configuration.nix
          ];
        };
        # primary server
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
        # laptop
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
        # router + appliances
        saguaro = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit userConfig inputs outputs; };
          modules = [
            ./hosts/saguaro/configuration.nix
          ];
        };
      };

      # Standalone home-manager for non-NixOS systems (macOS, other Linux)
      # Usage: home-manager switch --flake .#work --impure
      # Requires env vars: USER, HOME (auto-set by shell)
      homeConfigurations = {
        work = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = builtins.currentSystem or "aarch64-darwin";
            config.allowUnfree = true;
          };
          extraSpecialArgs = { inherit inputs; userConfig = null; };
          modules = [
            inputs.nixvim.homeModules.nixvim
            ./modules/home/alacritty/default.nix
            ./modules/home/atuin/default.nix
            ./modules/home/fish/default.nix
            ./modules/home/nixvim/default.nix
            ./modules/home/zellij/default.nix
            (_: {
              # Read from environment variables (requires --impure flag)
              home = {
                username = builtins.getEnv "USER";
                homeDirectory = builtins.getEnv "HOME";
                stateVersion = "23.11";
              };

              # Enable the portable modules
              mine.home = {
                alacritty.enable = true;
                atuin.enable = true;
                fish.enable = true;
                nixvim = {
                  enable = true;
                  enableSopsSecrets = false; # No sops on work machine
                };
                zellij.enable = true;
              };
            })
          ];
        };
      };

      # Container images
      packages.${system} = {
        audiobookshelf = nixos-generators.nixosGenerate {
          inherit system;
          format = "lxc";
          modules = [ ./containers/audiobookshelf.nix ];
          specialArgs = { inherit outputs userConfig inputs; };
        };
        audiobookshelfMetadata = nixos-generators.nixosGenerate {
          inherit system;
          format = "lxc-metadata";
          modules = [ ./containers/audiobookshelf.nix ];
          specialArgs = { inherit outputs userConfig inputs; };
        };
        changedetection = nixos-generators.nixosGenerate {
          inherit system;
          format = "lxc";
          modules = [ ./containers/changedetection.nix ];
          specialArgs = { inherit outputs userConfig inputs; };
        };
        changedetectionMetadata = nixos-generators.nixosGenerate {
          inherit system;
          format = "lxc-metadata";
          modules = [ ./containers/changedetection.nix ];
          specialArgs = { inherit outputs userConfig inputs; };
        };
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
        jellyfin = nixos-generators.nixosGenerate {
          inherit system;
          format = "lxc";
          modules = [ ./containers/jellyfin.nix ];
          specialArgs = { inherit outputs userConfig inputs; };
        };
        jellyfinMetadata = nixos-generators.nixosGenerate {
          inherit system;
          format = "lxc-metadata";
          modules = [ ./containers/jellyfin.nix ];
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
        miniflux = nixos-generators.nixosGenerate {
          inherit system;
          format = "lxc";
          modules = [ ./containers/miniflux.nix ];
          specialArgs = { inherit outputs userConfig inputs; };
        };
        minifluxMetadata = nixos-generators.nixosGenerate {
          inherit system;
          format = "lxc-metadata";
          modules = [ ./containers/miniflux.nix ];
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
        pocketId = nixos-generators.nixosGenerate {
          inherit system;
          format = "lxc";
          modules = [ ./containers/pocket-id.nix ];
          specialArgs = { inherit outputs userConfig inputs; };
        };
        pocketIdMetadata = nixos-generators.nixosGenerate {
          inherit system;
          format = "lxc-metadata";
          modules = [ ./containers/pocket-id.nix ];
          specialArgs = { inherit outputs userConfig inputs; };
        };
        searxng = nixos-generators.nixosGenerate {
          inherit system;
          format = "lxc";
          modules = [ ./containers/searxng.nix ];
          specialArgs = { inherit outputs userConfig inputs; };
        };
        searxngMetadata = nixos-generators.nixosGenerate {
          inherit system;
          format = "lxc-metadata";
          modules = [ ./containers/searxng.nix ];
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

      # Devshells managed in dedicated file
      devShells.${system} = import ./devshells.nix {
        pkgs = import nixpkgs { inherit system; };
        inherit self nixpkgs;
      };
    };
}

