#!/usr/bin/env fish

# Format Nix files
nixpkgs-fmt (git ls-files '*.nix')

# Run pre-commit on all files (if available)
if type -q pre-commit
    pre-commit run --all-files
else
    echo "pre-commit not found, running linters manually..."
    
    # Nix linters - skip hardware-configuration.nix files as configured in pre-commit
    if type -q statix
        echo "Running statix..."
        statix check . -i \
            '*hardware-configuration.nix'
    else
        echo "  statix not found, skipping"
    end
    
    if type -q deadnix
        echo "Running deadnix..."
        deadnix --fail (git ls-files '*.nix' | string match -v '*hardware-configuration.nix')
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
        pylint (git ls-files '*.py')
    else
        echo "  pylint not found, skipping"
    end
    
    echo "Manual linting complete!"
end
