### [❄️ Flake](https://www.youtube.com/watch?v=JCeYq72Sko0) for managing personal [NixOS](https://nixos.org/) systems

### 🛠️ Development and use

I typically generate NixOS and home-manager config in the same step, and then upgrade into the latest with:

```
nixos-rebuild switch --flake .#hostname
```

### 📁 Structure

```
.
├── .github                  # GitHub Actions workflow to lint code upon push to main
├── .pre-commit-config.yaml  # Nix store symlink generated upon devshell activation, target file is managed by [this flake][1]
├── flake.lock               # Input version control, managed by nix flake command
├── flake.nix                # Inputs (sources) and outputs (system configurations, devshells)
├── format.fish              # Shell script to format and lint project files
├── hosts                    # System/host definitions
├── lib                      # Helper functions and configuration patterns
├── modules                  # Used by host definitions
└── README.md                # 👋
```

[1](https://github.com/r6t/nixos-r6t/blob/6dc2d6c9bd67a276023f478f66f3c7e9ef2780a4/flake.nix#L83)

### ⌨️ devshell

This flake makes use of [devshells](https://github.com/numtide/devshell) to manage development environments.
Devshell activation is done via:

- Default/Nix: `nix develop`
- AWS: `nix develop .#aws`
