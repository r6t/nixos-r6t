{ pkgs, self, ... }:

let
  # --- Custom Package Definitions ---
  pick_1_6_0 = pkgs.python3.pkgs.buildPythonPackage rec {
    pname = "pick";
    version = "1.6.0";
    src = pkgs.fetchPypi {
      inherit pname version;
      hash = "sha256-Kv1GyJtQIxHTuDHs7hoA6Kv4kq1elubLr5PxcrKa4cU=";
    };
    pyproject = true;
    build-system = with pkgs.python3.pkgs; [
      poetry-core
    ];
  };

  qobuz-dl = pkgs.python3.pkgs.buildPythonApplication rec {
    pname = "qobuz-dl";
    version = "0.9.9.10";
    format = "pyproject";
    src = pkgs.fetchPypi {
      inherit pname version;
      hash = "sha256-q7TUl3scg+isoLB0xJvJLCtvJU7O+ogMlftt0O73qb4=";
    };
    nativeBuildInputs = with pkgs.python3.pkgs; [
      setuptools
      wheel
    ];
    propagatedBuildInputs = with pkgs.python3.pkgs; [
      requests
      pycryptodome
      mutagen
      rich
      itunespy
      pathvalidate
      tqdm
      pick_1_6_0
      beautifulsoup4
      colorama
    ];
  };

  # --- Shared Tool Definitions ---
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

  # --- Shell Helper Function ---

  mkShell = { name, extraPackages ? [ ] }:
    pkgs.mkShell {
      nativeBuildInputs = baseTools ++ [ pkgs.python3Packages.pip ];
      packages = pythonTools ++ nodeTools ++ extraPackages;
      shellHook = ''
        ${
          if pkgs.stdenv.hostPlatform.system == "x86_64-linux"
          then self.checks.${pkgs.stdenv.hostPlatform.system}.pre-commit-check.shellHook or ""
          else ""
        }
        export DEVSHELL_NAME="${name}"
        
        if command -v fish >/dev/null; then
          exec fish
        else
          echo "Warning: fish not found, falling back to bash"
        fi
      '';
    };

in
{
  # --- Shell Definitions ---

  default = mkShell { name = "nix"; };

  aws = pkgs.mkShell {
    AWS_REGION = "us-west-2";
    nativeBuildInputs = baseTools ++ (with pkgs; [
      awscli2
      nodejs_20
      ssm-session-manager-plugin
      nodePackages_latest.aws-cdk
    ]);
    # No Python packages - use Amazon toolbox Python to avoid conflicts with isengardcli
    packages = [ ];
    shell = "${pkgs.fish}/bin/fish";
    shellHook = ''
      ${
        if pkgs.stdenv.hostPlatform.system == "x86_64-linux"
        then self.checks.${pkgs.stdenv.hostPlatform.system}.pre-commit-check.shellHook or ""
        else ""
      }
      export DEVSHELL_NAME="aws"

      if command -v fish >/dev/null; then
        exec fish
      else
        echo "Warning: fish not found, falling back to bash"
      fi
    '';
  };

  media = mkShell {
    name = "media";
    extraPackages = with pkgs; [
      yt-dlp
      qobuz-dl
      (python3.withPackages (ps: with ps; [
        audible-cli
      ]))
    ];
  };
}

