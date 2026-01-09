#!/usr/bin/env fish

# Format Nix files
find . -name "*.nix" -exec nixpkgs-fmt {} +

# Run pre-commit on all files (if available)
if type -q pre-commit
    pre-commit run --all-files
else
    echo "pre-commit not found, running linters manually..."
    
    # Nix linters - skip hardware-configuration.nix files as configured in pre-commit
    if type -q statix
        echo "Running statix..."
        statix check . -i \
            'hosts/crown/hardware-configuration.nix' \
            'hosts/mountainball/hardware-configuration.nix' \
            'hosts/saguaro/configuration.nix'
    else
        echo "  statix not found, skipping"
    end
    
    if type -q deadnix
        echo "Running deadnix..."
        # Find all .nix files except hardware-configuration.nix
        find . -name "*.nix" ! -name "hardware-configuration.nix" -exec deadnix --fail {} +
    else
        echo "  deadnix not found, skipping"
    end
    
    # JavaScript/TypeScript linters
    if type -q prettier
        echo "Running prettier..."
        prettier --check .
    else
        echo "  prettier not found, skipping"
    end
    
    if type -q eslint
        echo "Running eslint..."
        eslint .
    else
        echo "  eslint not found, skipping"
    end
    
    # Python linters
    if type -q black
        echo "Running black..."
        black --check .
    else
        echo "  black not found, skipping"
    end
    
    if type -q isort
        echo "Running isort..."
        isort --check-only .
    else
        echo "  isort not found, skipping"
    end
    
    if type -q pylint
        echo "Running pylint..."
        find . -name "*.py" -exec pylint {} +
    else
        echo "  pylint not found, skipping"
    end
    
    echo "Manual linting complete!"
end
