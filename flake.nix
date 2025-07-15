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
      myCaddy = import ./pkgs/caddy-with-route53.nix {
        inherit pkgs lib;
      };
    in
    {
      overlays.saneFix = final: prev: {
        sane-backends = prev.sane-backends.overrideAttrs (_old: {
          doInstallCheck = false;
          installCheckPhase = "true";
        });
      };

      # Bare-metal hosts
      nixosConfigurations = {
        barrel = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit outputs userConfig inputs; };
          system = "x86_64-linux";
          modules = [
            ./hosts/barrel/configuration.nix
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
        exit-node = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit outputs userConfig inputs; };
          modules = [ ./hosts/exit-node/configuration.nix ];
        };
        mountainball = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit outputs userConfig inputs; };
          modules = [
            ./hosts/mountainball/configuration.nix
            {
              nixpkgs.overlays = [ self.overlays.saneFix ];
            }
          ];
        };
      };

      # Container and cloud images
      packages.${system} = {
        #	caddy = nixos-generators.nixosGenerate {
        #      	  inherit system;
        #      	  format = "lxc";
        #      	  modules = [ ./containers/caddy.nix ];
        #      	  specialArgs = { inherit outputs userConfig inputs; };
        #      	};
        #	caddy-metadata = nixos-generators.nixosGenerate {
        #      	  inherit system;
        #      	  format = "lxc-metadata";
        #      	  modules = [ ./containers/caddy.nix ];
        #      	  specialArgs = { inherit outputs userConfig inputs; };
        #      	};
        headscale = nixos-generators.nixosGenerate {
          inherit system;
          format = "amazon";
          modules = [ ./containers/headscale.nix ];
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
        exitNodeRouting = nixos-generators.nixosGenerate {
          inherit system;
          format = "lxc";
          modules = [ ./containers/exit-node-routing.nix ];
          specialArgs = { inherit outputs userConfig inputs; };
        };
        exitNodeRoutingMetadata = nixos-generators.nixosGenerate {
          inherit system;
          format = "lxc-metadata";
          modules = [ ./containers/exit-node-routing.nix ];
          specialArgs = { inherit outputs userConfig inputs; };
        };
        #        jellyfin = nixos-generators.nixosGenerate {
        #          inherit system;
        #          format = "lxc";
        #          modules = [ ./containers/jellyfin.nix ];
        #          specialArgs = { inherit outputs userConfig inputs; };
        #        };
        #        jellyfin-metadata = nixos-generators.nixosGenerate {
        #          inherit system;
        #          format = "lxc-metadata";
        #          modules = [ ./containers/jellyfin.nix ];
        #          specialArgs = { inherit outputs userConfig inputs; };
        #        };
      };

      # Pre-commit
      checks.${system} = {
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixpkgs-fmt.enable = true;
            statix.enable = false; # temporarily off, false positive
            deadnix.enable = false; # temporarily off, false positive
            prettier.enable = true;
            black.enable = true;
            isort.enable = true;
            eslint.enable = true;
            pylint.enable = true;
          };
        };
      };

      # Shells
      devShells.${system} =
        let
          pkgs = import nixpkgs { inherit system; };
          shellHookHelper = name: ''
            ${self.checks.${system}.pre-commit-check.shellHook or ""}
            export DEVSHELL_NAME="${name}"
          '';
          baseTools = with pkgs; [
            fish
          ];
          pythonTools = with pkgs; [
            (python3.withPackages (ps: with ps; [
              pip
              black
              pylint
              isort
              jq
              yq
            ]))
          ];
          nodeTools = with pkgs; [
            nodejs
            nodePackages.prettier
            nodePackages.eslint
          ];
        in
        {
          default = pkgs.mkShell {
            PIP_PREFIX = "${self}/_pip";
            PYTHONPATH = "$PIP_PREFIX/${pkgs.python3.sitePackages}:$PYTHONPATH";
            nativeBuildInputs = baseTools;
            packages = pythonTools ++ nodeTools;
            shellHook = ''
              ${shellHookHelper "nix"}
              if command -v fish >/dev/null; then
                exec fish
              else
                echo "Warning: fish not found, falling back to bash"
              fi
            '';
          };

          aws =
            let
              pkgs = import nixpkgs {
                inherit system;
                overlays = [
                  (_: prev: {
                    python3 = prev.python3.override {
                      packageOverrides = _: python-prev: {
                        awacs = python-prev.awacs.overridePythonAttrs (old: {
                          checkInputs = (old.checkInputs or [ ]) ++ [ python-prev.pytest ];
                        });
                      };
                    };
                  })
                ];
              };
            in
            pkgs.mkShell {
              AWS_REGION = "us-west-2";
              nativeBuildInputs = baseTools ++ (with pkgs; [
                awscli2
                nodejs_20
                ssm-session-manager-plugin
                nodePackages_latest.aws-cdk
              ]);
              packages = with pkgs; [
                (python3.withPackages (ps: with ps; [
                  boto3
                  troposphere
                ]))
              ];
              shell = "${pkgs.fish}/bin/fish";
              shellHook = ''
                ${shellHookHelper "aws"}
                if command -v fish >/dev/null; then
                  exec fish
                else
                  echo "Warning: fish not found, falling back to bash"
                fi
              '';
            };

          media = pkgs.mkShell {
            nativeBuildInputs = baseTools;
            packages = with pkgs; [
              yt-dlp
              (python3.withPackages (ps: with ps; [
                audible-cli
              ]))
            ];
            shell = "${pkgs.fish}/bin/fish";
            shellHook = ''
              ${shellHookHelper "media"}
              if command -v fish >/dev/null; then
                exec fish
              else
                echo "Warning: fish not found, falling back to bash"
              fi
            '';
          };
        };
    };
}

