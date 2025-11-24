## Rules

- only modify files that are part of this flake git project. for files outside this scope needing modification, tell me to do it.
- do not run git add, commit, or push actions
- do not run nixos rebuild or nix build actions
- do not run nix flake update or modify ./flake.lock

## Environment

- NixOS with flakes, manages multiple hosts and container images
- flake developement is almost exclusively done on the host "mountainball". assume you're running there unless I say otherwise in the prompt. this means commands to check systems other than mountainball cannot be run locally.
- fish shell. suggestions for shell actions should be done in fish
- after making changes to the nix flake, run ./format.fish and update flake code accordingly if needed.

### Structure

─ .github # GitHub Actions workflow to lint code upon push to main
─ .pre-commit-config.yaml # Nix store symlink generated upon devshell activation, target file is managed by flake.nix
─ containers # LXC image definitions
─ devshells.nix # Devshell declarations in a dedicated file to keep flake.nix tidy
─ flake.lock # Input version control, managed by nix flake command
─ flake.nix # Inputs (sources) and outputs (system configurations, devshells)
─ format.fish # Shell script to format and lint project files
─ hosts # System/host definitions
─ modules # Used by host and container definitions

## Code style

- Nix flake that manages multiple systems
- Repeated configurations are stored in modules, with host-specific details defined in hosts/
- Use options in modules where it makes sense, hardcoding general config values in modules is ok if I'm unlikely to use other options across my workstations and servers.
