## Rules

- only modify files that are part of this flake git project. for files outside this scope needing modification, tell me to do it.
- do not run git add, commit, or push actions
- do not run nixos rebuild actions
- do not run nix build actions
- do not run nix flake update or modify ./flake.lock

## Setup commands

- Validate code: `./format.fish`

## Code style

- Nix flake that manages multiple systems
- Repeated configurations are stored in modules, with host-specific details defined in hosts/
- Use options in modules where it makes sense, hardcoding general config values in modules is ok if I'm unlikely to use other options across my workstations and servers.

## Environment

- I almost always do flake development work on the host "mountainball" so if we're working on another host, consider that is almost certainly not the current host you're running on.
- fish shell. suggestions for shell actions should be done in fish
- NixOS with flakes
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
