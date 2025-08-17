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

  # --- Shell Helper Definitions ---
  shellHookHelper = name: ''
    ${self.checks.${pkgs.system}.pre-commit-check.shellHook or ""}
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
      # This 'pkgs' shadows the one from the outer scope, which is fine.
      pkgs = import pkgs.nixpkgs {
        inherit (pkgs) system;
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
      qobuz-dl
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
}

