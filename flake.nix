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
          devShellBasePkgs = with pkgs; [
            awscli2
            git
            nixpkgs-fmt
          ];

          baseShell = pkgs.mkShell {
            nativeBuildInputs = devShellBasePkgs ++ [ pkgs.fish ];
            buildInputs = devShellBasePkgs;
            shellHook = ''
              ${self.checks.${system}.pre-commit-check.shellHook}
              exec fish
            '';
          };
          system = "x86_64-linux";
          pkgs = import nixpkgs { inherit system; };
          pythonEnv = pkgs.python3.withPackages (ps: [
            ps.pip
          ]);
          flacAnalyzer = pkgs.python3Packages.buildPythonApplication {
            pname = "flac-analyzer";
            version = "0.1";
            format = "pyproject";
            src = ./scripts;
            propagatedBuildInputs = [ ];
          };
        in
        {
          default = baseShell.overrideAttrs (oldAttrs: {
            shellHook = ''
              export DEVSHELL_NAME="nix"
              ${oldAttrs.shellHook}
            '';
            buildInputs = oldAttrs.buildInputs ++ (with pkgs; [
              (python3.withPackages (ps: with ps; [
                pip
                black
                pylint
                isort
              ]))
              statix
              deadnix
              nodePackages.prettier
              nodePackages.eslint
              nodejs
              python311Packages.boto3
              python311Packages.pip
              python311Packages.troposphere
              python311Packages.jq
              python311Packages.yq
            ]);
          });

          aws = baseShell.overrideAttrs (oldAttrs: {
            shellHook = ''
              export AWS_REGION="us-west-2"
              export AWS_CDK_VERSION="$(cdk --version)"
              export PIP_PREFIX="$PWD/_pip"
              export PYTHONPATH="$PIP_PREFIX/${pkgs.python3.sitePackages}:$PYTHONPATH"
              export PATH="$PIP_PREFIX/bin:$PATH"
              unset SOURCE_DATE_EPOCH
              export DEVSHELL_NAME="aws"
              ${oldAttrs.shellHook}
            '';
            buildInputs = oldAttrs.buildInputs ++ (with pkgs; [
              (python3.withPackages (ps: with ps; [
                awscli2
                aws-cdk
                nodejs_20
                troposphere
                boto3
              ]))
              # nodePackages.aws-cdk
              nodePackages_latest.aws-cdk
              nodePackages.prettier
              nodePackages.eslint
              nodejs
              ssm-session-manager-plugin
            ]);
          });

          media = baseShell.overrideAttrs (oldAttrs: {
            shellHook = ''
              export AWS_REGION="us-west-2"
              export AWS_CDK_VERSION="$(cdk --version)"
              export PIP_PREFIX="$PWD/_pip"
              export PYTHONPATH="$PIP_PREFIX/${pkgs.python3.sitePackages}:$PYTHONPATH"
              export PATH="$PIP_PREFIX/bin:$PATH"
              unset SOURCE_DATE_EPOCH
              export DEVSHELL_NAME="media"
              ${oldAttrs.shellHook}
            '';
            buildInputs = oldAttrs.buildInputs ++ (with pkgs; [
              (python3.withPackages (ps: with ps; [
                audible-cli
              ]))
              yt-dlp
            ]);
          });

          flac = baseShell.overrideAttrs (oldAttrs: {
            shellHook = ''
                            export AWS_REGION="us-west-2"
                            export AWS_CDK_VERSION="$(cdk --version)"
                            export PIP_PREFIX="$PWD/_pip"
                            export PYTHONPATH="$PIP_PREFIX/${pkgs.python3.sitePackages}:$PYTHONPATH"
                            export PATH="$PIP_PREFIX/bin:$PATH"
                            unset SOURCE_DATE_EPOCH
                            export DEVSHELL_NAME="aws"
              	      echo "FLAC Analyzer devshell activated."
                            echo "Run: flac-analyze /path/to/flacs"
                            ${oldAttrs.shellHook}
            '';
            buildInputs = oldAttrs.buildInputs ++ (with pkgs; [
              (python3.withPackages (ps: with ps; [
                pythonEnv
                sox
                flac
                flacAnalyzer
                pip
                black
                pylint
                isort
              ]))
            ]);
          });

        };
    };
}
