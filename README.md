### [❄️ Flake](https://www.youtube.com/watch?v=JCeYq72Sko0) for managing personal [NixOS](https://nixos.org/) systems 🖧  💻 🖥️

### Development and use 🛠️
I typically generate NixOS and home-manager config in the same step, and then upgrade into the latest with:
```
nixos-rebuild switch --flake .#hostname
```

This project makes use of a [Nix devshell](https://github.com/numtide/devshell) and pre-commit hooks that are made available system-wide from within this flake. Enabling these can be done once the flake manages the system by running the following from the project directory:
```
nix develop
pre-commit install
```

### Structure 📁
```
.
├── .github                  # GitHub Actions workflow to lint code upon push to main
├── .pre-commit-config.yaml  # # Nix store symlink, target file is managed by [this flake][1]


Nix store symlink, target file is managed by [this flake](https://github.com/r6t/nixos-r6t/blob/6dc2d6c9bd67a276023f478f66f3c7e9ef2780a4/flake.nix#L83)
├── flake.lock               # Input version control, managed by nix flake command
├── flake.nix                # Inputs (sources) and outputs (system configurations)
├── format.fish              # Shell script to format and lint project files
├── hosts                    # System/host definitions
├── modules                  # Used by host definitions
└── README.md                # 👋
 ```
