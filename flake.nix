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
  outputs = { self, nixos-generators, nixpkgs, pre-commit-hooks, ... } @inputs:
    let
      userConfig = {
        username = "r6t";
        homeDirectory = "/home/r6t";
      };
      inherit (self) outputs;
      inherit (nixpkgs) lib;
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      overlays = {
        # prepended _ means deadnix will ignore structurally required but unused argument
        saneFix = _final: prev: {
          sane-backends = prev.sane-backends.overrideAttrs (_oldAttrs: {
            doInstallCheck = false;
            installCheckPhase = "true";
          });
        };
        osmGpsMapFix = final: prev: {
          osm-gps-map = prev.osm-gps-map.overrideAttrs (oldAttrs: {
            nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ final.automake final.autoconf ];
            preBuild = ''
              # Create symlinks for version-specific tools that the build expects
              mkdir -p $TMPDIR/bin
              ln -sf ${final.automake}/bin/aclocal $TMPDIR/bin/aclocal-1.16
              ln -sf ${final.automake}/bin/automake $TMPDIR/bin/automake-1.16
              ln -sf ${final.autoconf}/bin/autoconf $TMPDIR/bin/autoconf-2.71
              ln -sf ${final.autoconf}/bin/autoheader $TMPDIR/bin/autoheader-2.71
              ln -sf ${final.autoconf}/bin/autoreconf $TMPDIR/bin/autoreconf-2.71
              export PATH="$TMPDIR/bin:$PATH"
            '';
          });
        };
      };
      # Bare-metal hosts
      nixosConfigurations = {
        crown = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit outputs userConfig inputs; };
          system = "x86_64-linux";
          modules = [
            ./hosts/crown/configuration.nix
            {
              nixpkgs = {
                config = {
                  allowUnfree = true;
                  cudaSupport = true;
                  nvidia.acceptLicense = true;
                };
              };
            }
          ];
        };
        mountainball = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit outputs userConfig inputs; };
          modules = [
            ./hosts/mountainball/configuration.nix
            {
              nixpkgs = {
                overlays = [ self.overlays.saneFix self.overlays.osmGpsMapFix ];
                config = {
                  allowUnfree = true;
                  # workaround until [https://github.com/NixOS/nixpkgs/pull/429473](https://github.com/NixOS/nixpkgs/pull/429473) is merged
                  permittedInsecurePackages = [
                    "libsoup-2.74.3"
                  ];
                };
              };
            }
          ];
        };
      };
      # Container and images
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
        ollama = nixos-generators.nixosGenerate {
          inherit system;
          format = "lxc";
          modules = [ ./containers/ollama.nix ];
          specialArgs = { inherit outputs userConfig inputs; };
        };
        ollamaMetadata = nixos-generators.nixosGenerate {
          inherit system;
          format = "lxc-metadata";
          modules = [ ./containers/ollama.nix ];
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
      devShells.${system} = import ./devshells.nix { inherit pkgs self nixpkgs; };
    };
}

