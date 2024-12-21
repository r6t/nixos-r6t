#!/usr/bin/env fish

# Format Nix files
find . -name "*.nix" -exec nixpkgs-fmt {} +

# Run pre-commit on all files
pre-commit run --all-files
