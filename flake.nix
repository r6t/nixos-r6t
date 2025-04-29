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

    #    sops-ryan = {
    #      url = "git+https://git-codecommit.us-west-2.amazonaws.com/v1/repos/sops-ryan?ref=main";
    #      flake = false;
    #    };

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
      inherit (nixpkgs) lib;
      system = "x86_64-linux";
    in
    {
      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = {
        # nixos networking device
        exit-node = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit outputs userConfig inputs; };
          modules = [ ./hosts/exit-node/configuration.nix ];
        };
        # nixos gpu server
        moon = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit outputs userConfig inputs; };
          modules = [ ./hosts/moon/configuration.nix ];
        };
        # nixos laptop
        mountainball = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit outputs userConfig inputs; };
          modules = [ ./hosts/mountainball/configuration.nix ];
        };
        # nixos server
        saguaro = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit outputs userConfig inputs; };
          modules = [ ./hosts/saguaro/configuration.nix ];
        };
        # nixos desktop
        silvertorch = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit outputs userConfig inputs; };
          modules = [ ./hosts/silvertorch/configuration.nix ];
        };
      };

      checks.${system} = {
        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            nixpkgs-fmt.enable = true;
            statix.enable = true;
            deadnix.enable = true;
            prettier.enable = true;
            black.enable = true;
            isort.enable = true;
            eslint.enable = true;
            pylint.enable = true;
          };
        };
      };

      devShells.${system} =
        let
          pkgs = import nixpkgs {
            inherit system;
          };
          baseShell = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [
              git
              nixpkgs-fmt
              fish
            ];

            shellHook = ''
              ${self.checks.${system}.pre-commit-check.shellHook}
              export DEVSHELL_NAME="base"
              exec fish
            '';
          };

          pythonTools = with pkgs; [
            (python3.withPackages (ps: with ps; [
              pip
              black
              pylint
              isort
              boto3
              troposphere
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
          # Default shell: Nix + Python + Style
          default = pkgs.mkShell {
            inputsFrom = [ baseShell ];
            packages = pythonTools ++ nodeTools ++ (with pkgs; [
              statix
              deadnix
            ]);

            # AWS shell: CDK + base tools

            aws = pkgs.mkShell {
              inputsFrom = [ baseShell self.devShells.${system}.default ];
              packages = with pkgs; [
                awscli2
                aws-cdk
                nodejs_20
                ssm-session-manager-plugin
                nodePackages_latest.aws-cdk
              ];
              shellHook = ''
                export DEVSHELL_NAME="aws"
                ${self.devShells.${system}.default.shellHook}
              '';
            };
          };

          # Media shell: Media tools + base
          media = pkgs.mkShell {
            inputsFrom = [ baseShell self.devShells.${system}.default ];
            packages = with pkgs; [
              yt-dlp
              (python3.withPackages (ps: with ps; [
                audible-cli
              ]))
            ];
            shellHook = ''
              export DEVSHELL_NAME="media"
              ${self.devShells.${system}.default.shellHook}
            '';
          };

        };
    };
}
