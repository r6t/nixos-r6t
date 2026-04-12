## Rules

- only modify files that are part of this flake git project. for files outside this scope needing modification, tell me to do it. one exception: you can mkdir in /tmp and use any directories that you created in /tmp for things like downloading git repos to inspect
- never run git add, commit, or push actions
- never run nixos rebuild, nix build, home-manager switch, or any nix commands that build/activate configurations
- never run nix flake update or modify ./flake.lock

## Environment

- NixOS with flakes, manages multiple hosts and container images
- flake developement is almost exclusively done on the host "mountainball". assume you're running there unless I say otherwise in the prompt. this means commands to check systems other than mountainball cannot be run locally.
- fish shell. suggestions for shell actions should be done in fish
- after making changes to the nix flake, run ./format.fish and update flake code accordingly if needed.
- every module must be listed on modules/default.nix

### Structure

─ .github # GitHub Actions workflow to lint code upon push to main
─ .pre-commit-config.yaml # Nix store symlink generated upon devshell activation, target file is managed by flake.nix
─ containers/ # LXC image definitions (every \*.nix is a buildable image)
─ containers/lib/ # Shared base layers and add-ons for containers (not buildable)
─ containers/build.py # Builds container images and imports to incus
─ containers/relaunch.py # Relaunches running containers with newer images
─ devshells.nix # Devshell declarations in a dedicated file to keep flake.nix tidy
─ flake.lock # Input version control, managed by nix flake command
─ flake.nix # Inputs (sources) and outputs (system configurations, devshells, container images)
─ format.fish # Shell script to format and lint project files
─ hosts/ # System/host definitions
─ hosts/{host}/incus-instances/ # Incus profile YAMLs and cloud-init seed files per host
─ modules/ # NixOS and home-manager modules, used by hosts and containers
─ docs/ # Detailed guides for LLMs and humans (loaded via opencode.json)

## Code style

- Repeated configurations are stored in modules, with host-specific details defined in hosts/
- Use options in modules where it makes sense, hardcoding general config values in modules is ok if I'm unlikely to use other options across my workstations and servers.

## HA API access

Token is at `/run/secrets/HA_MCP_TOKEN`.

```bash
# Quick state check
curl -s -H "Authorization: Bearer $(cat /run/secrets/HA_MCP_TOKEN)" https://homeassistant.r6t.io/api/

# Get all entities of a domain
curl -s -H "Authorization: Bearer $(cat /run/secrets/HA_MCP_TOKEN)" https://homeassistant.r6t.io/api/states \
  | python3 -c "import json,sys; [print(s['entity_id'], s['state']) for s in json.load(sys.stdin) if s['entity_id'].startswith('light.')]"
```

## Incus containers

When working on incus container tasks (creating, modifying, or debugging LXC containers), read @docs/INCUS.md first. It documents the full pipeline from NixOS container definition through build, deployment, networking, and runtime configuration.
