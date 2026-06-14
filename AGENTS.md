## Rules

- only modify files that are part of this flake git project. for files outside this scope needing modification, tell me to do it. one exception: you can mkdir in /tmp and use any directories that you created in /tmp for things like downloading git repos to inspect
- never run git add, commit, or push actions under any circumstances
- never run nixos rebuild, nix build, home-manager switch, or any nix commands that build/activate configurations under any circumstances
- never run `containers/build.py` or `containers/relaunch.py` under any circumstances
- never run nix flake update or modify ./flake.lock under any circumstances

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
─ .agents/skills/ # Task-specific workflows shared by Codex and OpenCode
─ docs/ # Detailed reference guides for LLMs and humans, loaded on demand by skills
─ opencode.json # Project-level opencode config. Must live at repo root for opencode's auto-discovery to find it (walks up from CWD to git root); cannot be moved into docs/ or .config/.

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

## Task-specific guidance

Use the matching skill under `.agents/skills/` before working in these areas:

- Incus containers and LXC images: `incus`
- Neovim and nixvim: `nixvim`
- llama.cpp, model serving, and local LLM tuning: `llm-hosting`
- Shared colors and application theming: `theming`
- Host freezes and hardware-specific troubleshooting: `host-troubleshooting`

Load detailed files only when relevant to the task. Do not preemptively read every file in `docs/`.
