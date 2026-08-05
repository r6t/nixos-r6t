### [Flake](https://www.youtube.com/watch?v=JCeYq72Sko0) modules for personal [NixOS](https://nixos.org/) systems

![](./docs/nixos-r6t-flake.drawio.svg)

### Public/Private Split

This repository is the public module/profile layer. Real host inventory lives in a
separate private wrapper flake so hardware identifiers, network topology, storage
paths, and runtime runbooks do not have to be public.

Public outputs are reusable modules, profiles, checks, and devshells. The main
dendritic API for downstream flakes is `modules.nixos.*`.
Concrete `nixosConfigurations` are intentionally not exported here.

See `docs/PRIVATE-FLAKE.md` for the private wrapper pattern.

### NixOS and Home Manager

Private host flakes import profiles from this repo and build NixOS plus Home
Manager in one step. A private host rebuild can still use a local helper such as:

```fish
nrs
```

`nrs` is a fish function from `modules/home/fish/config.nix` that rebuilds the
current host from the configured flake path.

### Containers

[Incus](https://linuxcontainers.org/incus/) image definitions and runtime
profiles are private because they expose service inventory, bind mounts, domains,
LAN layout, and passthrough devices.

### Structure

```
.
├── docs/                    # Reference docs for humans and agents
├── flake/                   # flake-parts output modules and discovery helpers
├── modules/                 # NixOS, Home Manager, Flatpak, and profile modules
├── pkgs/                    # Optional custom package outputs
├── devshells.nix            # Devshell declarations
├── flake.nix                # Inputs and flake-parts root
├── format.fish              # Format and lint entrypoint
└── README.md
```

See `docs/DENDRITIC.md` for the current flake structure and public output
contract.

### devshell

I'm increasingly making use of [devshells](https://github.com/numtide/devshell) to manage nixpkgs that activate on-demand. Basically an OS-level virtual environment.
Devshell activation is done via a [shell function](https://github.com/r6t/nixos-r6t/blob/bddac92b6da1879f021f0b3f7875e4dd65acefe0/modules/home/fish/default.nix#L55) to allow quick devshell activation without explicitly specifying my flake path:

- Default/Nix: `nd`
- Add name argument for other devshells. Ex: `nd aws`
