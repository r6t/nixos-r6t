{ pkgs, self, ... }:

let
  codexAgentsFile = pkgs.writeText "codex-agents.md" ''
    # Personal Development Preferences

    ## Safety

    - Never run Git write actions, including `git add`, `git commit`, `git push`, `git reset`, `git rebase`, or commands that modify branches, tags, the index, or repository history.
    - Never run build or activation actions, including `nix build`, `nixos-rebuild`, `home-manager switch`, or equivalent commands.
    - Read-only Git inspection and non-building Nix evaluation are allowed unless repository instructions say otherwise.

    ## Implementation

    - Make the smallest correct change that satisfies the request.
    - Prefer existing project patterns, standard libraries, native platform features, and installed dependencies.
    - Do not add speculative abstractions, dependencies, configuration, compatibility layers, or files.
    - Optimize for conceptual simplicity and reviewability, not raw line count.
    - Keep changes within the requested behavior and leave unrelated cleanup alone.
    - Delete obsolete code when the change makes it unnecessary.
    - Preserve trust-boundary validation, security, accessibility, and safeguards against data loss.

    ## Judgment

    - Inspect the repository before choosing an approach.
    - Verify uncertain claims and state material assumptions briefly.
    - Challenge requirements only when a substantially simpler solution meets the same goal; otherwise implement the request.
    - Follow repository instructions over these preferences whenever they conflict.

    ## Verification

    - Scale tests and checks to the risk and blast radius of the change.
    - Prefer the repository's existing validation commands.
    - Report anything that could not be verified.

    ## Communication

    - Lead with the result.
    - Be concise and direct. Explain only important decisions, tradeoffs, risks, assumptions, and failed verification.
    - Do not include feature tours, generic advice, repetition, or lengthy justification for straightforward changes.
  '';

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
    codex
    fish
  ];
  pythonTools = with pkgs; [
    (python3.withPackages (ps: with ps; [
      black
      chardet
      isort
      jq
      lxml
      openpyxl
      pip
      pylint
      pypdf
      python-docx
      pyyaml
      yq
    ]))
  ];
  nodeTools = with pkgs; [
    nodejs
    prettier
    eslint
  ];

  # --- Shell Helper Function ---

  baseShellHook = name: ''
    mkdir -p "$HOME/.codex"
    ln -sfn "${codexAgentsFile}" "$HOME/.codex/AGENTS.md"
    export DEVSHELL_NAME="${name}"
  '';

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
        ${baseShellHook name}
      '';
    };

  # --- AWS Base Configuration ---
  # Shared packages and environment for aws devshell
  awsBase = {
    nativeBuildInputs = baseTools ++ (with pkgs; [
      awscli2
      aws-cdk-cli
      cfn-nag
      nodejs_24
      python3
      ssm-session-manager-plugin
      uv
    ]);
    packages = [ ];
  };

  # AWS devshell shellHook - for personal NixOS systems
  awsShellHook = ''
    ${
      if pkgs.stdenv.hostPlatform.system == "x86_64-linux"
      then self.checks.${pkgs.stdenv.hostPlatform.system}.pre-commit-check.shellHook or ""
      else ""
    }
    ${baseShellHook "aws"}
    # Python CDK: aws-cdk-lib/constructs/cdk-nag aren't in nixpkgs (weekly releases),
    # so they live in a project-local uv venv. Pin uv to this shell's Nix Python
    # instead of letting it download its own interpreter.
    export UV_PYTHON_PREFERENCE="only-system"
    export UV_PYTHON="${pkgs.python3}/bin/python3"
  '';

in
{
  # --- Shell Definitions ---

  default = mkShell { name = "nix"; };

  # AWS devshell - for personal NixOS systems
  # Uses mkShell to include standard build toolchain for flexibility
  aws = pkgs.mkShell (awsBase // {
    shellHook = awsShellHook;
  });

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
